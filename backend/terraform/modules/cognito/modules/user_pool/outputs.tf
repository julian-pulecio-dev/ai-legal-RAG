output "id" {
  value = aws_cognito_user_pool.this.id
}

output "arn" {
  value = aws_cognito_user_pool.this.arn
}

output "endpoint" {
  description = "Endpoint del User Pool (sin protocolo), usado para construir el issuer OIDC."
  value       = aws_cognito_user_pool.this.endpoint
}

output "name" {
  value = aws_cognito_user_pool.this.name
}
