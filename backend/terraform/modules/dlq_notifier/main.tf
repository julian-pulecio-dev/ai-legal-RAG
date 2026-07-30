# Module "dlq_notifier": Lambda triggered directly by the document-uploaded
# DLQ. It sends a rich email per failed message (payload, attempts,
# timestamps, and the original traceback if document_ingest stored one)
# and deletes the message once notified. If notifying itself keeps
# failing, the message is kept for retry up to MAX_NOTIFY_ATTEMPTS (see
# handler.py), then dropped instead of looping forever.

module "package" {
  source = "../lambda_package"

  name       = "dlq_notifier"
  source_dir = var.source_path
}

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-${var.environment}-dlq-notifier-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "sqs_consume" {
  name = "${var.project_name}-${var.environment}-dlq-notifier-sqs-consume"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
      ]
      Resource = var.dlq_arn
    }]
  })
}

resource "aws_sns_topic" "dlq_notifications" {
  name = "${var.project_name}-${var.environment}-dlq-notifications"

  tags = var.tags
}

resource "aws_sns_topic_subscription" "dlq_notifications_email" {
  topic_arn = aws_sns_topic.dlq_notifications.arn
  protocol  = "email"
  endpoint  = var.alerts_email
}

resource "aws_iam_role_policy" "sns_publish" {
  name = "${var.project_name}-${var.environment}-dlq-notifier-sns-publish"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = aws_sns_topic.dlq_notifications.arn
    }]
  })
}

# Lets ErrorNotifier look up the traceback document_ingest stored for a
# messageId, since this Lambda's own invocation never saw the exception
# that made the message end up in the DLQ.
resource "aws_iam_role_policy" "error_log_read" {
  name = "${var.project_name}-${var.environment}-dlq-notifier-error-log-read"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "dynamodb:GetItem"
      Resource = var.error_log_table_arn
    }]
  })
}

module "lambda" {
  source = "../lambda_function"

  function_name = "${var.project_name}-${var.environment}-dlq-notifier"
  role_arn      = aws_iam_role.lambda.arn

  filename         = module.package.output_path
  source_code_hash = module.package.source_code_hash

  handler = "handler.handler"
  runtime = "python3.13"

  timeout            = var.timeout
  memory_size        = var.memory_size
  log_retention_days = var.log_retention_days
  tags               = var.tags

  layers = [var.error_handler_layer_arn]

  environment_variables = {
    topic_dlq_notifications = aws_sns_topic.dlq_notifications.arn
    error_log_table         = var.error_log_table_name
  }

  depends_on = [aws_iam_role_policy_attachment.basic_execution]
}

# One message per invocation: batching several failed documents into a
# single email would blur which one failed, and DLQ volume is expected to
# be low (it only fills up when document_ingest can't process something
# after 3 attempts).
resource "aws_lambda_event_source_mapping" "dlq" {
  event_source_arn = var.dlq_arn
  function_name    = module.lambda.arn

  batch_size              = 1
  function_response_types = ["ReportBatchItemFailures"]
}
