variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "cognito_app_client_id" {
  description = "Client ID del App Client de Cognito; se usa como audience del JWT authorizer."
  type        = string
}

variable "cognito_issuer_url" {
  description = "Issuer OIDC del User Pool de Cognito (https://cognito-idp.<region>.amazonaws.com/<pool_id>)."
  type        = string
}

variable "cors_allowed_origins" {
  description = "Orígenes permitidos para el frontend React (ej. http://localhost:5173, https://app.midominio.com)."
  type        = list(string)
}

variable "stage_name" {
  type    = string
  default = "$default"
}

variable "throttling_burst_limit" {
  type    = number
  default = 20
}

variable "throttling_rate_limit" {
  type    = number
  default = 10
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
