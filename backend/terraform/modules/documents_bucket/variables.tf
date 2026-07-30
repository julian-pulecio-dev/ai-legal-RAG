variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "versioning_enabled" {
  description = "Enables versioning so overwritten or deleted documents can be recovered."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allows deleting the bucket even if it contains objects. Use with care in prod."
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
