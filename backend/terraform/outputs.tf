output "cognito_user_pool_id" {
  value = module.cognito.user_pool_id
}

output "cognito_app_client_id" {
  value = module.cognito.app_client_id
}

output "cognito_issuer_url" {
  value = module.cognito.issuer_url
}

output "api_endpoint" {
  value = module.api_gateway.api_endpoint
}

output "aws_region" {
  value = var.aws_region
}
