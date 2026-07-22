variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "ai-chatbot"
}

variable "environment" {
  description = "dev, staging o prod."
  type        = string
  default     = "dev"
}

variable "cors_allowed_origins" {
  description = "Orígenes permitidos a llamar la API (frontend React: dev server y dominio de producción)."
  type        = list(string)
  default     = ["http://localhost:5173"]
}

variable "mfa_configuration" {
  description = "OFF, ON u OPTIONAL."
  type        = string
  default     = "OPTIONAL"
}

variable "password_min_length" {
  type    = number
  default = 12
}

variable "deletion_protection" {
  type    = bool
  default = false
}
