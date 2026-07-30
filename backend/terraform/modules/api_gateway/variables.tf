variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "cognito_app_client_id" {
  description = "Client ID of the Cognito App Client; used as the JWT authorizer's audience."
  type        = string
}

variable "cognito_issuer_url" {
  description = "OIDC issuer of the Cognito User Pool (https://cognito-idp.<region>.amazonaws.com/<pool_id>)."
  type        = string
}

variable "cors_allowed_origins" {
  description = "Origins allowed for the React frontend (e.g. http://localhost:5173, https://app.mydomain.com)."
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
