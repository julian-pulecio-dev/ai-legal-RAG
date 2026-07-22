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
    Flujos de auth permitidos para este cliente. Por requerimiento del flujo
    de login (SRP), no se incluye ALLOW_USER_PASSWORD_AUTH (envía la
    contraseña en texto plano dentro de la request, aunque sea sobre TLS).
  EOT
  type        = list(string)
  default     = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]

  validation {
    condition     = !contains(var.explicit_auth_flows, "ALLOW_USER_PASSWORD_AUTH")
    error_message = "Este cliente debe usar SRP; no habilites ALLOW_USER_PASSWORD_AUTH."
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
  description = "Atributos que el app client puede leer del usuario."
  type        = list(string)
  default     = ["email", "email_verified", "name"]
}

variable "write_attributes" {
  description = "Atributos que el app client puede escribir/actualizar."
  type        = list(string)
  default     = ["email", "name"]
}

variable "enable_token_revocation" {
  type    = bool
  default = true
}
