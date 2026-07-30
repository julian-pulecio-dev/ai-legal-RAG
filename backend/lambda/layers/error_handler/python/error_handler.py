import json
import logging
import sys
import time
import traceback
from datetime import datetime, timezone

import boto3

logger = logging.getLogger()

_ERROR_TTL_SECONDS = 30 * 24 * 3600  # keep stored tracebacks for 30 days


class ErrorNotifier:
    """Logs an error and publishes it to SNS, attaching the SQS record's
    delivery trace (attempts, timestamps, payload) so on-call has enough
    context without digging through CloudWatch.

    If constructed with a table_name, it also persists the traceback of
    live exceptions to DynamoDB (keyed by messageId) and can look it back
    up later. That's needed because by the time a message reaches the DLQ,
    the Lambda invocation that originally raised the exception has already
    ended and its traceback no longer exists anywhere else.
    """

    def __init__(self, topic_arn, table_name=None, sns_client=None, dynamodb_resource=None):
        self.topic_arn = topic_arn
        self.sns = sns_client or boto3.client("sns")

        self.table = None
        if table_name:
            dynamodb_resource = dynamodb_resource or boto3.resource("dynamodb")
            self.table = dynamodb_resource.Table(table_name)

    def log_error(self, record, summary):
        """Logs the error and stores its traceback (if any) for later
        lookup, but does NOT send a notification. Use this for errors that
        will be retried and, if they keep failing, get their own definitive
        notification once they land in the DLQ — this avoids emailing once
        per retry attempt for the same message."""
        message = self._build_message(record, summary)
        logger.error(message)

    def log_and_notify(self, record, summary, subject, footer="", stored_traceback=None):
        message = self._build_message(record, summary, stored_traceback)
        if footer:
            message = f"{message}\n\n{footer}"

        logger.error(message)
        self.sns.publish(TopicArn=self.topic_arn, Subject=subject, Message=message)

    def _build_message(self, record, summary, stored_traceback=None):
        message_id = record["messageId"]
        message = f"{summary}\n\n{self.trace_details(record)}"

        live_traceback = self._current_traceback()
        exception_traceback = live_traceback or stored_traceback
        if exception_traceback:
            message = f"{message}\n\nTraceback:\n{exception_traceback}"

        if live_traceback:
            self._store_traceback(message_id, live_traceback)

        return message

    def get_stored_traceback(self, message_id):
        """Looks up the traceback ErrorNotifier stored for this messageId
        during an earlier (failed) processing attempt. Returns None if
        there's no table configured or nothing was stored."""
        if not self.table:
            return None
        try:
            response = self.table.get_item(Key={"message_id": message_id})
        except Exception:
            logger.exception("Failed to look up stored traceback for %s", message_id)
            return None
        item = response.get("Item")
        return item["traceback"] if item else None

    def _store_traceback(self, message_id, exception_traceback):
        if not self.table:
            return
        try:
            self.table.put_item(
                Item={
                    "message_id": message_id,
                    "traceback": exception_traceback,
                    "expires_at": int(time.time()) + _ERROR_TTL_SECONDS,
                }
            )
        except Exception:
            logger.exception("Failed to store traceback for %s", message_id)

    @classmethod
    def trace_details(cls, record):
        attributes = record.get("attributes", {})
        return (
            f"Delivery attempts: {attributes.get('ApproximateReceiveCount', 'unknown')}\n"
            f"First received at: "
            f"{cls._epoch_ms_to_iso(attributes.get('ApproximateFirstReceiveTimestamp'))}\n"
            f"Enqueued at: {cls._epoch_ms_to_iso(attributes.get('SentTimestamp'))}\n"
            f"Payload: {cls._pretty_json(record['body'])}"
        )

    @staticmethod
    def _pretty_json(body):
        try:
            return json.dumps(json.loads(body), indent=2)
        except ValueError:
            return body

    @staticmethod
    def _epoch_ms_to_iso(value):
        try:
            return datetime.fromtimestamp(int(value) / 1000, tz=timezone.utc).isoformat()
        except (TypeError, ValueError):
            return "unknown"

    @staticmethod
    def _current_traceback():
        # Only meaningful when called from inside an except block (e.g.
        # document_ingest's handler); a no-op otherwise (e.g. dlq_notifier,
        # which notifies about a failure that already happened elsewhere).
        if sys.exc_info()[0] is None:
            return None
        return traceback.format_exc()
