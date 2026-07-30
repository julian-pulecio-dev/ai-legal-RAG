# App Client for the React frontend (SPA). No client secret: a secret in a
# SPA can't be kept confidential (it would live in the browser's JS), so
# Cognito doesn't issue one for this type of client.
resource "aws_cognito_user_pool_client" "this" {
  name         = "${var.project_name}-${var.environment}-app-client"
  user_pool_id = var.user_pool_id

  generate_secret = false

  explicit_auth_flows = var.explicit_auth_flows

  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = var.enable_token_revocation

  access_token_validity  = var.access_token_validity_minutes
  id_token_validity      = var.id_token_validity_minutes
  refresh_token_validity = var.refresh_token_validity_days

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  read_attributes  = var.read_attributes
  write_attributes = var.write_attributes
}
