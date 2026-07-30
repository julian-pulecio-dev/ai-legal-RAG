variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "sqs_queue_arn" {
  description = "ARN of the document-uploaded SQS queue that triggers this Lambda."
  type        = string
}

variable "source_path" {
  description = "Path to the directory with the Lambda's source code (handler.py)."
  type        = string
}

variable "alerts_email" {
  description = "Email subscribed to the SNS topic for non-transient configuration errors."
  type        = string
}

variable "error_handler_layer_arn" {
  description = "ARN of the shared error_handler Lambda layer (ErrorNotifier class)."
  type        = string
}

variable "error_log_table_name" {
  description = "Name of the shared DynamoDB table where ErrorNotifier stores error tracebacks."
  type        = string
}

variable "error_log_table_arn" {
  description = "ARN of the shared DynamoDB table where ErrorNotifier stores error tracebacks."
  type        = string
}

variable "documents_bucket_name" {
  description = "Name of the S3 bucket documents are uploaded to (validated against the event's bucket)."
  type        = string
}

variable "documents_bucket_arn" {
  description = "ARN of the S3 bucket documents are uploaded to, used to scope the GetObject IAM permission."
  type        = string
}

variable "vector_storage_queue_arn" {
  description = "ARN of the vector-storage SQS queue this Lambda sends embedded vectors to."
  type        = string
}

variable "vector_storage_queue_url" {
  description = "URL of the vector-storage SQS queue this Lambda sends embedded vectors to."
  type        = string
}

variable "embedding_model_id" {
  description = "Bedrock foundation model ID used to generate embeddings."
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}

variable "embedding_dimension" {
  description = "Embedding vector size requested from the embedding model. Must match the S3 Vectors index's dimension."
  type        = number
  default     = 1024
}

variable "batch_size" {
  description = "Number of SQS messages per invocation. Kept at 1 so each invocation embeds a single S3 document."
  type        = number
  default     = 1
}

variable "max_concurrency" {
  description = "Maximum number of concurrent Lambda invocations the SQS event source mapping is allowed to trigger."
  type        = number
  default     = 5
}

variable "timeout" {
  type    = number
  default = 30
}

variable "memory_size" {
  type    = number
  default = 256
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
