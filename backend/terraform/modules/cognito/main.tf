# Module "cognito": groups the identity directory resources.
# No Identity Pool is created: the frontend doesn't need temporary AWS
# credentials, only the JWTs issued by the User Pool to authenticate
# against our own API via API Gateway.

module "user_pool" {
  source = "./modules/user_pool"

  project_name = var.project_name
  environment  = var.environment

  deletion_protection = var.deletion_protection

  password_min_length              = var.password_min_length
  password_require_lowercase       = var.password_require_lowercase
  password_require_uppercase       = var.password_require_uppercase
  password_require_numbers         = var.password_require_numbers
  password_require_symbols         = var.password_require_symbols
  temporary_password_validity_days = var.temporary_password_validity_days

  mfa_configuration       = var.mfa_configuration
  mfa_methods             = var.mfa_methods
  advanced_security_mode  = var.advanced_security_mode
  custom_attributes       = var.custom_attributes
  name_attribute_required = var.name_attribute_required

  tags = var.tags
}

module "app_client" {
  source = "./modules/app_client"

  project_name = var.project_name
  environment  = var.environment
  user_pool_id = module.user_pool.id

  access_token_validity_minutes = var.access_token_validity_minutes
  id_token_validity_minutes     = var.id_token_validity_minutes
  refresh_token_validity_days   = var.refresh_token_validity_days

  read_attributes  = var.app_client_read_attributes
  write_attributes = var.app_client_write_attributes
}
