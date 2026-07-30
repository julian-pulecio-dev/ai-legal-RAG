# Module "document_ingest": Lambda that consumes the document-uploaded SQS
# queue, one S3 object per invocation, embeds the chunk's text with Bedrock
# Titan, and forwards the resulting vector + metadata to the vector-storage
# SQS queue for the vector_storage Lambda to persist.

data "aws_region" "current" {}

locals {
  embedding_model_arn = "arn:aws:bedrock:${data.aws_region.current.region}::foundation-model/${var.embedding_model_id}"
}

module "package" {
  source = "../lambda_package"

  name       = "document_ingest"
  source_dir = var.source_path
}

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-${var.environment}-document-ingest-lambda-role"

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
  name = "${var.project_name}-${var.environment}-document-ingest-sqs-consume"
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
      Resource = var.sqs_queue_arn
    }]
  })
}

# Notifies by email the (non-transient) configuration errors that the
# handler decides not to retry. Direct email subscription: no need for an
# intermediate queue since the only consumer today is a person.
resource "aws_sns_topic" "scalable_errors" {
  name = "${var.project_name}-${var.environment}-document-ingest-scalable-errors"

  tags = var.tags
}

resource "aws_sns_topic_subscription" "scalable_errors_email" {
  topic_arn = aws_sns_topic.scalable_errors.arn
  protocol  = "email"
  endpoint  = var.alerts_email
}

resource "aws_iam_role_policy" "sns_publish" {
  name = "${var.project_name}-${var.environment}-document-ingest-sns-publish"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = aws_sns_topic.scalable_errors.arn
    }]
  })
}

# Lets ErrorNotifier persist the traceback of errors it notifies about, so
# dlq_notifier can retrieve it later by messageId (its own invocation, once
# the message finally lands in the DLQ, no longer has that exception).
resource "aws_iam_role_policy" "error_log_write" {
  name = "${var.project_name}-${var.environment}-document-ingest-error-log-write"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "dynamodb:PutItem"
      Resource = var.error_log_table_arn
    }]
  })
}

# Read-only: this Lambda fetches the JSON chunk file to embed it. Writes
# into the bucket are the responsibility of whoever uploads documents.
resource "aws_iam_role_policy" "documents_bucket_read" {
  name = "${var.project_name}-${var.environment}-document-ingest-documents-read"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "s3:GetObject"
      Resource = "${var.documents_bucket_arn}/*"
    }]
  })
}

resource "aws_iam_role_policy" "embedding_model_invoke" {
  name = "${var.project_name}-${var.environment}-document-ingest-embedding-model"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "bedrock:InvokeModel"
      Resource = local.embedding_model_arn
    }]
  })
}

resource "aws_iam_role_policy" "vector_storage_queue_send" {
  name = "${var.project_name}-${var.environment}-document-ingest-vector-storage-send"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sqs:SendMessage"
      Resource = var.vector_storage_queue_arn
    }]
  })
}

module "lambda" {
  source = "../lambda_function"

  function_name = "${var.project_name}-${var.environment}-document-ingest"
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
    topic_scalable_errors    = aws_sns_topic.scalable_errors.arn
    error_log_table          = var.error_log_table_name
    documents_bucket         = var.documents_bucket_name
    embedding_model_id       = var.embedding_model_id
    embedding_dimension      = tostring(var.embedding_dimension)
    vector_storage_queue_url = var.vector_storage_queue_url
  }

  depends_on = [aws_iam_role_policy_attachment.basic_execution]
}

# Each invocation processes a single S3 event (batch_size = 1). Concurrency
# across invocations is capped at max_concurrency so at most that many
# documents get embedded in parallel. function_response_types enables
# partial batch failure reporting: without it, whatever the handler returns
# in "batchItemFailures" is ignored and SQS deletes the whole batch even if
# the handler marked the message for retry.
resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = var.sqs_queue_arn
  function_name    = module.lambda.arn

  batch_size              = var.batch_size
  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = var.max_concurrency
  }
}
