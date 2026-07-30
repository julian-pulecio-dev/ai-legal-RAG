import json
import logging
import os

from error_handler import ErrorNotifier

logger = logging.getLogger()
logger.setLevel(logging.INFO)

error_notifier = ErrorNotifier(
    os.environ["topic_dlq_notifications"],
    table_name=os.environ.get("error_log_table"),
)

# If notifying keeps failing (SNS down, bad IAM, ...), retrying forever
# would loop silently since the only alert mechanism is the thing that's
# broken. Give up after this many attempts instead.
MAX_NOTIFY_ATTEMPTS = 3


def handler(event, context):
    fails = []

    for record in event["Records"]:
        message_id = record["messageId"]

        try:
            _notify(record)
        except Exception:
            attempt = _attempt_count(record)
            if attempt >= MAX_NOTIFY_ATTEMPTS:
                # Give up: the message is dropped from the DLQ, but its
                # traceback (if any) is still in DynamoDB, so it's still
                # findable by messageId in CloudWatch/DynamoDB.
                logger.critical(
                    "Giving up on DLQ notification for %s after %s attempts",
                    message_id,
                    attempt,
                    exc_info=True,
                )
                continue

            # Kept in the queue for retry until we notify or give up.
            logger.exception("Failed to send DLQ notification for %s", message_id)
            fails.append({"itemIdentifier": message_id})

    return {"batchItemFailures": fails}


def _attempt_count(record):
    # Fails closed: this count exists to cap retries, so if it can't be
    # read for some reason, assume the cap is already hit rather than
    # risking an infinite loop by always assuming attempt 1.
    try:
        return int(record.get("attributes", {}).get("ApproximateReceiveCount", MAX_NOTIFY_ATTEMPTS))
    except (TypeError, ValueError):
        return MAX_NOTIFY_ATTEMPTS


def _notify(record):
    message_id = record["messageId"]

    summary = "A message exhausted all retries and was moved to the dead-letter queue."
    document = _describe_document(record["body"])
    if document:
        summary = f"{summary}\nDocument: {document}"

    error_notifier.log_and_notify(
        record,
        summary,
        subject=f"Document ingest: message sent to DLQ ({message_id[:8]})",
        footer="This message has been removed from the DLQ after this notification.",
        stored_traceback=error_notifier.get_stored_traceback(message_id),
    )


def _describe_document(body):
    try:
        detail = json.loads(body)["detail"]
        return f"s3://{detail['bucket']['name']}/{detail['object']['key']}"
    except (ValueError, KeyError, TypeError):
        return None
