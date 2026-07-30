import json
import logging
import os

from botocore.exceptions import ClientError

from error_handler import ErrorNotifier
from storage import VectorStorageWriter

logger = logging.getLogger()
logger.setLevel(logging.INFO)

error_notifier = ErrorNotifier(
    os.environ["topic_scalable_errors"],
    table_name=os.environ.get("error_log_table"),
)

# Error codes returned by boto3/botocore inside ClientError.response
# (raised by the s3vectors client's PutVectors call), not actual exception
# classes.
TRANSIENT_ERROR_CODES = {"ThrottlingException"}
SCALABLE_ERROR_CODES = {"ResourceNotFoundException", "AccessDeniedException"}


def _summarize_record(record):
    # Logs the vector's key/metadata but not the embedding itself: a batch
    # of 100 records x 1024 floats would bloat CloudWatch for little
    # benefit, so we only note how many dimensions it had.
    try:
        message = json.loads(record["body"])
    except (TypeError, ValueError):
        return {"messageId": record.get("messageId")}

    return {
        "messageId": record.get("messageId"),
        "key": message.get("key"),
        "vector_dimensions": len(message.get("vector", [])),
        "metadata": message.get("metadata"),
    }


def handler(event, context):
    records = event["Records"]
    logger.info(
        "Received %d record(s): %s",
        len(records),
        json.dumps([_summarize_record(r) for r in records]),
    )

    all_item_ids = [{"itemIdentifier": r["messageId"]} for r in records]

    writer = VectorStorageWriter(
        vector_bucket_name=os.environ["vector_bucket_name"],
        vector_index_name=os.environ["vector_index_name"],
    )

    try:
        writer.put_batch(records)
    except ClientError as e:
        error_code = e.response["Error"]["Code"]

        if error_code in TRANSIENT_ERROR_CODES:
            # transient: retried later via the DLQ. We don't notify because
            # it's expected to resolve itself (e.g. throttling).
            result = {"batchItemFailures": all_item_ids}
            logger.info("Returning: %s", json.dumps(result))
            return result

        if error_code in SCALABLE_ERROR_CODES:
            # configuration error, not transient: retrying won't help (e.g.
            # the index doesn't exist or a permission is missing). The
            # whole batch is discarded and the team is notified, using the
            # first message in the batch as a representative sample.
            error_notifier.log_and_notify(
                records[0],
                f"Configuration error writing a batch of {len(records)} vectors: {e}",
                "Vector storage: configuration error",
            )
            result = {"batchItemFailures": []}
            logger.info("Returning: %s", json.dumps(result))
            return result

        raise
    except Exception as e:
        # unexpected error: retried like a transient one (it might be a
        # fluke); if it keeps failing, the messages land in the DLQ and
        # vector_storage_dlq_notifier sends the definitive notification.
        # Logged (not just retried) using the first message in the batch as
        # a representative sample, same as the ClientError/scalable branch.
        error_notifier.log_error(
            records[0], f"Error writing a batch of {len(records)} vectors: {e}"
        )
        result = {"batchItemFailures": all_item_ids}
        logger.info("Returning: %s", json.dumps(result))
        return result

    result = {"batchItemFailures": []}
    logger.info("Returning: %s", json.dumps(result))
    return result
