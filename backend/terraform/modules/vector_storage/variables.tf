variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "sqs_queue_arn" {
  description = "ARN of the vector-storage SQS queue that triggers this Lambda."
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

variable "vector_index_arn" {
  description = "ARN of the S3 Vectors index this Lambda writes to, used to scope the PutVectors IAM permission."
  type        = string
}

variable "vector_bucket_name" {
  description = "Name of the S3 Vectors bucket passed to PutVectors."
  type        = string
}

variable "vector_index_name" {
  description = "Name of the S3 Vectors index passed to PutVectors."
  type        = string
}

variable "batch_size" {
  type    = number
  default = 100
}

variable "maximum_batching_window_in_seconds" {
  type    = number
  default = 30
}

variable "timeout" {
  type    = number
  default = 60
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
