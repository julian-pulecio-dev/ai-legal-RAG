variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "documents_bucket_name" {
  description = "Name of the legal documents S3 bucket whose ObjectCreated events are filtered."
  type        = string
}

variable "log_retention_days" {
  description = "Retention in days for the CloudWatch log groups."
  type        = number
  default     = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
