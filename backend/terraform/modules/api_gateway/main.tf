# Módulo "api_gateway": HTTP API (API Gateway v2) protegida por un JWT
# authorizer que valida los tokens emitidos por el User Pool de Cognito.
#
# No se definen rutas/integraciones aquí: esas se agregan cuando existan los
# backends (Lambdas, etc.) que las implementen, referenciando
# aws_apigatewayv2_authorizer.cognito.id como authorizer_id de cada ruta
# protegida.

resource "aws_apigatewayv2_api" "this" {
  name          = "${var.project_name}-${var.environment}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins     = var.cors_allowed_origins
    allow_methods     = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    allow_headers     = ["content-type", "authorization"]
    allow_credentials = false
    max_age           = 300
  }

  tags = var.tags
}

# Valida el access_token (o id_token, según lo que envíe el frontend) contra
# el issuer y la audience del App Client. API Gateway verifica la firma y
# expiración por su cuenta, antes de invocar cualquier integración.
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.this.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.project_name}-${var.environment}-cognito-authorizer"

  jwt_configuration {
    audience = [var.cognito_app_client_id]
    issuer   = var.cognito_issuer_url
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.this.arn
    format = jsonencode({
      requestId         = "$context.requestId"
      ip                = "$context.identity.sourceIp"
      requestTime       = "$context.requestTime"
      httpMethod        = "$context.httpMethod"
      routeKey          = "$context.routeKey"
      status            = "$context.status"
      protocol          = "$context.protocol"
      responseLength    = "$context.responseLength"
      integrationError  = "$context.integrationErrorMessage"
      authorizerError   = "$context.authorizer.error"
    })
  }

  default_route_settings {
    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
  }

  tags = var.tags
}
