import json
import logging
import os

from botocore.exceptions import ClientError

from error_handler import ErrorNotifier
from ingestion import DocumentEmbedder

logger = logging.getLogger()
logger.setLevel(logging.INFO)

error_notifier = ErrorNotifier(
    os.environ["topic_scalable_errors"],
    table_name=os.environ.get("error_log_table"),
)

# Error codes returned by boto3/botocore inside ClientError.response
# (raised by the S3/Bedrock/SQS clients), not actual exception classes.
TRANSIENT_ERROR_CODES = {"ThrottlingException"}
SCALABLE_ERROR_CODES = {"ResourceNotFoundException", "AccessDeniedException"}


def handler(event, context):
    logger.info("Received event: %s", json.dumps(event))

    fails = []

    for record in event["Records"]:
        try:
            embedder = DocumentEmbedder(
                bucket_name=os.environ["documents_bucket"],
                embedding_model_id=os.environ["embedding_model_id"],
                embedding_dimension=int(os.environ["embedding_dimension"]),
                vector_storage_queue_url=os.environ["vector_storage_queue_url"],
            )
            embedder.process_record(record)

        except ClientError as e:
            error_code = e.response["Error"]["Code"]

            if error_code in TRANSIENT_ERROR_CODES:
                # transient: retried later via the DLQ. We don't notify
                # because it's expected to resolve itself (e.g. throttling).
                fails.append({"itemIdentifier": record["messageId"]})
                continue

            if error_code in SCALABLE_ERROR_CODES:
                # configuration error, not transient: retrying won't help
                # (e.g. the bucket doesn't exist or a permission is missing).
                # The message is discarded and the team is notified.
                error_notifier.log_and_notify(
                    record,
                    f"Configuration error processing {record['messageId']}: {e}",
                    "Document ingest: configuration error",
                )
                continue

            raise
        except Exception as e:
            # unexpected error: retried like a transient one (it might be a
            # fluke), but unlike transient errors we log + store the
            # traceback per retry: dlq_notifier sends the single,
            # definitive notification once retries are exhausted.
            error_notifier.log_error(record, f"Error processing {record['messageId']}: {e}")
            fails.append({"itemIdentifier": record["messageId"]})

    result = {"batchItemFailures": fails}
    logger.info("Returning: %s", json.dumps(result))
    return result
