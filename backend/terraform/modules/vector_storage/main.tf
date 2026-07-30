# Module "vector_storage": Lambda that consumes the vector-storage SQS
# queue in batches (fan-in) and writes each batch to the S3 Vectors index
# with a single PutVectors call.

module "package" {
  source = "../lambda_package"

  name       = "vector_storage"
  source_dir = var.source_path
}

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-${var.environment}-vector-storage-lambda-role"

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
  name = "${var.project_name}-${var.environment}-vector-storage-sqs-consume"
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

resource "aws_iam_role_policy" "put_vectors" {
  name = "${var.project_name}-${var.environment}-vector-storage-put-vectors"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "s3vectors:PutVectors"
      Resource = var.vector_index_arn
    }]
  })
}

# Notifies by email the (non-transient) configuration errors that the
# handler decides not to retry. Direct email subscription: no need for an
# intermediate queue since the only consumer today is a person.
resource "aws_sns_topic" "scalable_errors" {
  name = "${var.project_name}-${var.environment}-vector-storage-scalable-errors"

  tags = var.tags
}

resource "aws_sns_topic_subscription" "scalable_errors_email" {
  topic_arn = aws_sns_topic.scalable_errors.arn
  protocol  = "email"
  endpoint  = var.alerts_email
}

resource "aws_iam_role_policy" "sns_publish" {
  name = "${var.project_name}-${var.environment}-vector-storage-sns-publish"
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
  name = "${var.project_name}-${var.environment}-vector-storage-error-log-write"
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

module "lambda" {
  source = "../lambda_function"

  function_name = "${var.project_name}-${var.environment}-vector-storage"
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
    topic_scalable_errors = aws_sns_topic.scalable_errors.arn
    error_log_table       = var.error_log_table_name
    vector_bucket_name    = var.vector_bucket_name
    vector_index_name     = var.vector_index_name
  }

  depends_on = [aws_iam_role_policy_attachment.basic_execution]
}

# Triggers the Lambda once a batch of 100 messages builds up, or, if
# there's at least one message in the queue, once 30 seconds pass without
# reaching that size. function_response_types enables partial batch
# failure reporting: without it, whatever the handler returns in
# "batchItemFailures" is ignored and SQS deletes the whole batch even if
# the handler marked messages for retry.
resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = var.sqs_queue_arn
  function_name    = module.lambda.arn

  batch_size                         = var.batch_size
  maximum_batching_window_in_seconds = var.maximum_batching_window_in_seconds
  function_response_types            = ["ReportBatchItemFailures"]
}
