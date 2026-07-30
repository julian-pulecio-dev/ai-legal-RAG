# Allows API Gateway (v1 and v2) to write access/execution logs to
# CloudWatch. This is an account/region-level setting, so it lives in the
# root instead of inside the api_gateway module (avoids conflicts if the
# module is instantiated more than once).
resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${var.project_name}-${var.environment}-apigw-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role       = aws_iam_role.api_gateway_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

module "cognito" {
  source = "./modules/cognito"

  project_name = var.project_name
  environment  = var.environment

  deletion_protection = var.deletion_protection
  password_min_length = var.password_min_length
  mfa_configuration   = var.mfa_configuration
}

module "api_gateway" {
  source = "./modules/api_gateway"

  project_name = var.project_name
  environment  = var.environment

  cognito_app_client_id = module.cognito.app_client_id
  cognito_issuer_url    = module.cognito.issuer_url

  cors_allowed_origins = var.cors_allowed_origins

  depends_on = [aws_api_gateway_account.this]
}

module "documents_bucket" {
  source = "./modules/documents_bucket"

  project_name = var.project_name
  environment  = var.environment

  versioning_enabled = var.documents_bucket_versioning_enabled
  force_destroy      = var.documents_bucket_force_destroy
}

module "event_notification" {
  source = "./modules/event_notification"

  project_name = var.project_name
  environment  = var.environment

  documents_bucket_name = module.documents_bucket.id
  log_retention_days    = var.event_log_retention_days
}

# Shared error-logging/SNS-notification helper (ErrorNotifier), used by any
# Lambda that consumes SQS records and needs to report failures with a
# consistent delivery trace. A layer avoids duplicating this code (and its
# boto3/SNS wiring) across every consumer.
module "error_handler_layer" {
  source = "./modules/lambda_layer"

  name       = "${var.project_name}-${var.environment}-error-handler"
  source_dir = "${path.root}/../lambda/layers/error_handler"
}

# Stores the traceback of errors document_ingest hits, keyed by messageId,
# so dlq_notifier can retrieve it once the message ends up in the DLQ (its
# own invocation never sees the original exception).
module "error_log_table" {
  source = "./modules/error_log_table"

  name = "${var.project_name}-${var.environment}-error-log"
}

# S3 Vectors store that both document_ingest (via embedding_dimension, to
# keep the model config and index dimension from drifting apart) and
# vector_storage (PutVectors) rely on.
module "vector_store" {
  source = "./modules/vector_store"

  project_name = var.project_name
  environment  = var.environment

  dimension = var.embedding_dimension
}

# Queue that document_ingest publishes embedded vectors to, and
# vector_storage drains in batches to write into S3 Vectors.
module "vector_storage_queue" {
  source = "./modules/vector_storage_queue"

  project_name = var.project_name
  environment  = var.environment
}

module "document_ingest" {
  source = "./modules/document_ingest"

  project_name = var.project_name
  environment  = var.environment

  sqs_queue_arn = module.event_notification.document_uploaded_queue_arn
  source_path   = "${path.root}/../lambda/document_ingest"

  error_handler_layer_arn = module.error_handler_layer.arn
  error_log_table_name    = module.error_log_table.name
  error_log_table_arn     = module.error_log_table.arn

  documents_bucket_name = module.documents_bucket.id
  documents_bucket_arn  = module.documents_bucket.arn

  vector_storage_queue_arn = module.vector_storage_queue.queue_arn
  vector_storage_queue_url = module.vector_storage_queue.queue_url

  embedding_model_id  = var.embedding_model_id
  embedding_dimension = var.embedding_dimension

  log_retention_days = var.event_log_retention_days
  alerts_email       = var.alerts_email
}

module "vector_storage" {
  source = "./modules/vector_storage"

  project_name = var.project_name
  environment  = var.environment

  sqs_queue_arn = module.vector_storage_queue.queue_arn
  source_path   = "${path.root}/../lambda/vector_storage"

  error_handler_layer_arn = module.error_handler_layer.arn
  error_log_table_name    = module.error_log_table.name
  error_log_table_arn     = module.error_log_table.arn

  vector_index_arn   = module.vector_store.index_arn
  vector_bucket_name = module.vector_store.vector_bucket_name
  vector_index_name  = module.vector_store.index_name

  log_retention_days = var.event_log_retention_days
  alerts_email       = var.alerts_email
}

module "dlq_notifier" {
  source = "./modules/dlq_notifier"

  project_name = var.project_name
  environment  = var.environment

  dlq_arn     = module.event_notification.document_uploaded_dlq_arn
  source_path = "${path.root}/../lambda/dlq_notifier"

  error_handler_layer_arn = module.error_handler_layer.arn
  error_log_table_name    = module.error_log_table.name
  error_log_table_arn     = module.error_log_table.arn

  log_retention_days = var.event_log_retention_days
  alerts_email       = var.alerts_email
}

# Second instance of the generic dlq_notifier module: notifies on messages
# that the vector_storage Lambda couldn't process after exhausting retries
# (e.g. a malformed vector payload or a persistent PutVectors failure).
module "vector_storage_dlq_notifier" {
  source = "./modules/dlq_notifier"

  project_name = "${var.project_name}-vector-storage"
  environment  = var.environment

  dlq_arn     = module.vector_storage_queue.dlq_arn
  source_path = "${path.root}/../lambda/dlq_notifier"

  error_handler_layer_arn = module.error_handler_layer.arn
  error_log_table_name    = module.error_log_table.name
  error_log_table_arn     = module.error_log_table.arn

  log_retention_days = var.event_log_retention_days
  alerts_email       = var.alerts_email
}
