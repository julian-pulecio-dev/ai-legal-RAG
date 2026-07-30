variable "function_name" {
  type = string
}

variable "role_arn" {
  description = "ARN of the execution IAM role. Defined outside this module because permissions vary by use case (e.g. access to a specific SQS queue)."
  type        = string
}

variable "filename" {
  description = "Path to the code .zip (typically the lambda_package module's output_path)."
  type        = string
}

variable "source_code_hash" {
  description = "Code hash (typically the lambda_package module's source_code_hash), triggers a redeploy when it changes."
  type        = string
}

variable "handler" {
  type = string
}

variable "runtime" {
  type    = string
  default = "python3.13"
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

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "layers" {
  description = "ARNs of Lambda layers to attach (e.g. shared code used by several functions)."
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
