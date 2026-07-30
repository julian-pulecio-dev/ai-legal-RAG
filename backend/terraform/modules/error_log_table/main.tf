# Module "error_log_table": stores the traceback of errors document_ingest
# hits while processing a record, keyed by SQS messageId. dlq_notifier
# looks it up when a message ends up in the DLQ, since by then the Lambda
# invocation that actually raised the exception has already ended and its
# traceback no longer exists anywhere else.

resource "aws_dynamodb_table" "this" {
  name         = var.name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "message_id"

  attribute {
    name = "message_id"
    type = "S"
  }

  # Debug data, not meant to be kept forever: auto-expire old entries.
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = var.tags
}
