variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "dlq_arn" {
  description = "ARN of the dead-letter queue to consume and notify about."
  type        = string
}

variable "source_path" {
  description = "Path to the directory with the Lambda's source code (handler.py)."
  type        = string
}

variable "alerts_email" {
  description = "Email subscribed to the SNS topic for DLQ notifications."
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
