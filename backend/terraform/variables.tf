variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "ai-chatbot"
}

variable "environment" {
  description = "dev, staging, or prod."
  type        = string
  default     = "dev"
}

variable "cors_allowed_origins" {
  description = "Origins allowed to call the API (React frontend: dev server and production domain)."
  type        = list(string)
  default     = ["http://localhost:5173"]
}

variable "mfa_configuration" {
  description = "OFF, ON, or OPTIONAL."
  type        = string
  default     = "OFF"
}

variable "password_min_length" {
  type    = number
  default = 12
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "documents_bucket_versioning_enabled" {
  description = "Enables versioning on the legal documents bucket."
  type        = bool
  default     = true
}

variable "documents_bucket_force_destroy" {
  description = "Allows deleting the documents bucket even if it contains objects. Use with care in prod."
  type        = bool
  default     = false
}

variable "event_log_retention_days" {
  description = "Retention in days for the EventBridge pipeline's CloudWatch log groups."
  type        = number
  default     = 30
}

variable "alerts_email" {
  description = "Email subscribed to the SNS topic for non-transient document ingest configuration errors."
  type        = string
}

variable "embedding_model_id" {
  description = "Bedrock foundation model ID document_ingest uses to generate embeddings."
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}

variable "embedding_dimension" {
  description = "Embedding vector size. Shared by the S3 Vectors index and document_ingest's embedding model configuration."
  type        = number
  default     = 1024
}
