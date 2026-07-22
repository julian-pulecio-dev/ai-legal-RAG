variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "password_min_length" {
  type    = number
  default = 12
}

variable "password_require_lowercase" {
  type    = bool
  default = true
}

variable "password_require_uppercase" {
  type    = bool
  default = true
}

variable "password_require_numbers" {
  type    = bool
  default = true
}

variable "password_require_symbols" {
  type    = bool
  default = true
}

variable "temporary_password_validity_days" {
  type    = number
  default = 7
}

variable "mfa_configuration" {
  type    = string
  default = "OPTIONAL"
}

variable "mfa_methods" {
  type    = list(string)
  default = ["TOTP"]
}

variable "advanced_security_mode" {
  type    = string
  default = "AUDIT"
}

variable "custom_attributes" {
  type = list(object({
    name       = string
    type       = string
    mutable    = bool
    min_length = optional(number)
    max_length = optional(number)
  }))
  default = []
}

variable "name_attribute_required" {
  type    = bool
  default = true
}

variable "access_token_validity_minutes" {
  type    = number
  default = 60
}

variable "id_token_validity_minutes" {
  type    = number
  default = 60
}

variable "refresh_token_validity_days" {
  type    = number
  default = 30
}

variable "app_client_read_attributes" {
  type    = list(string)
  default = ["email", "email_verified", "name"]
}

variable "app_client_write_attributes" {
  type    = list(string)
  default = ["email", "name"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
