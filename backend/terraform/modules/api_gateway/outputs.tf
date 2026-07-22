output "api_id" {
  value = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  value = aws_apigatewayv2_stage.this.invoke_url
}

output "execution_arn" {
  value = aws_apigatewayv2_api.this.execution_arn
}

output "authorizer_id" {
  description = "ID del JWT authorizer de Cognito, para asociarlo a rutas protegidas."
  value       = aws_apigatewayv2_authorizer.cognito.id
}

output "stage_name" {
  value = aws_apigatewayv2_stage.this.name
}
