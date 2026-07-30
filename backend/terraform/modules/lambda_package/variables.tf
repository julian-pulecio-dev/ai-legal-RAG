variable "name" {
  description = "Unique package name (used to name the generated .zip, e.g. \"document_ingest\")."
  type        = string
}

variable "source_dir" {
  description = "Directory with the Lambda function's source code to package."
  type        = string
}
