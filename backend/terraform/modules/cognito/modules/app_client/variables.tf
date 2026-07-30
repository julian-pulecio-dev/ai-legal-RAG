variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "user_pool_id" {
  type = string
}

variable "explicit_auth_flows" {
  description = <<-EOT
    Auth flows allowed for this client. Per the login flow's requirement
    (SRP), ALLOW_USER_PASSWORD_AUTH is not included (it sends the password
    in plain text within the request body, even over TLS).
  EOT
  type        = list(string)
  default     = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]

  validation {
    condition     = !contains(var.explicit_auth_flows, "ALLOW_USER_PASSWORD_AUTH")
    error_message = "This client must use SRP; do not enable ALLOW_USER_PASSWORD_AUTH."
  }
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

variable "read_attributes" {
  description = "Attributes the app client can read from the user."
  type        = list(string)
  default     = ["email", "email_verified", "name"]
}

variable "write_attributes" {
  description = "Attributes the app client can write/update."
  type        = list(string)
  default     = ["email", "name"]
}

variable "enable_token_revocation" {
  type    = bool
  default = true
}
