# Module "event_notification": EventBridge pipeline that logs document
# upload events to CloudWatch Logs and, for audit purposes, every event
# that passes through the default bus.

data "aws_caller_identity" "current" {}

module "document_uploads_log" {
  source = "./modules/log_group"

  name              = "/aws/events/${var.project_name}-${var.environment}/document-uploads"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

module "all_events_log" {
  source = "./modules/log_group"

  name              = "/aws/events/${var.project_name}-${var.environment}/all-events"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# Filters only the "Object Created" events from the legal documents bucket.
module "document_uploaded_rule" {
  source = "./modules/event_rule"

  name        = "${var.project_name}-${var.environment}-document-uploaded"
  description = "Detects when a document is uploaded to the legal documents bucket."

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [var.documents_bucket_name]
      }
    }
  })

  log_group_arn = module.document_uploads_log.arn
  tags          = var.tags
}

# DLQ: receives the messages the document_uploaded consumer fails to
# process after exhausting its retries. dlq_notifier consumes it, emails
# the team, and deletes the message; visibility timeout only needs to
# cover a normal invocation (recommended: 6x the Lambda's timeout) so a
# failed notification attempt is retried reasonably soon.
resource "aws_sqs_queue" "document_uploaded_dlq" {
  name = "${var.project_name}-${var.environment}-document-uploaded-dlq"

  visibility_timeout_seconds = 180

  tags = var.tags
}

# SQS queue: second target of the document_uploaded rule. This is what the
# ingestion pipeline (embeddings, etc.) eventually consumes. Visibility
# timeout is 6x document_ingest's Lambda timeout (AWS's recommendation) so
# a batch that's still processing doesn't become visible again and get
# picked up by a second, overlapping invocation.
resource "aws_sqs_queue" "document_uploaded" {
  name = "${var.project_name}-${var.environment}-document-uploaded"

  visibility_timeout_seconds = 180

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.document_uploaded_dlq.arn
    maxReceiveCount     = 3
  })

  tags = var.tags
}

resource "aws_sqs_queue_policy" "document_uploaded_eventbridge" {
  queue_url = aws_sqs_queue.document_uploaded.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowEventBridgeToSendMessage"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.document_uploaded.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = module.document_uploaded_rule.arn
        }
      }
    }]
  })
}

resource "aws_cloudwatch_event_target" "document_uploaded_to_sqs" {
  rule = module.document_uploaded_rule.name
  arn  = aws_sqs_queue.document_uploaded.arn
}

# "Catch-all" rule: accepts absolutely every event on the default bus (it
# only filters by account, which always matches) to keep a full audit log
# in CloudWatch.
module "all_events_rule" {
  source = "./modules/event_rule"

  name        = "${var.project_name}-${var.environment}-all-events"
  description = "Captures every event on the default bus for auditing in CloudWatch."

  event_pattern = jsonencode({
    account = [data.aws_caller_identity.current.account_id]
  })

  log_group_arn = module.all_events_log.arn
  tags          = var.tags
}

# EventBridge needs explicit permission (a resource policy) to write to
# the destination log groups.
resource "aws_cloudwatch_log_resource_policy" "eventbridge" {
  policy_name = "${var.project_name}-${var.environment}-eventbridge-to-logs"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowEventBridgeToCloudWatchLogs"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
      Resource = [
        "${module.document_uploads_log.arn}:*",
        "${module.all_events_log.arn}:*",
      ]
      Condition = {
        ArnLike = {
          "aws:SourceArn" = [
            module.document_uploaded_rule.arn,
            module.all_events_rule.arn,
          ]
        }
      }
    }]
  })
}
