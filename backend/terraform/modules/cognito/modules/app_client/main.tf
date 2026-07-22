# App Client para el frontend React (SPA). Sin client secret: un secret en
# una SPA no se puede mantener confidencial (viviría en el JS del navegador),
# así que Cognito no lo emite para este tipo de cliente.
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
