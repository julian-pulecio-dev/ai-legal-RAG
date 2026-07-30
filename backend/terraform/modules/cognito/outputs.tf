output "user_pool_id" {
  value = module.user_pool.id
}

output "user_pool_arn" {
  value = module.user_pool.arn
}

output "user_pool_endpoint" {
  value = module.user_pool.endpoint
}

output "issuer_url" {
  description = "OIDC issuer of the User Pool, used by API Gateway's JWT authorizer."
  value       = "https://${module.user_pool.endpoint}"
}

output "app_client_id" {
  value = module.app_client.id
}
