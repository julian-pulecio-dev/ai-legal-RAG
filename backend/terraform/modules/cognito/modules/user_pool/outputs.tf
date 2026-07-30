output "id" {
  value = aws_cognito_user_pool.this.id
}

output "arn" {
  value = aws_cognito_user_pool.this.arn
}

output "endpoint" {
  description = "User Pool endpoint (without protocol), used to build the OIDC issuer."
  value       = aws_cognito_user_pool.this.endpoint
}

output "name" {
  value = aws_cognito_user_pool.this.name
}
