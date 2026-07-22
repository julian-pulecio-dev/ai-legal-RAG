# Permite que API Gateway (v1 y v2) escriba logs de acceso/ejecución en
# CloudWatch. Es una configuración a nivel de cuenta/región, por eso vive en
# el root y no dentro del módulo api_gateway (evita conflictos si el módulo
# se instancia más de una vez).
resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${var.project_name}-${var.environment}-apigw-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role       = aws_iam_role.api_gateway_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

module "cognito" {
  source = "./modules/cognito"

  project_name = var.project_name
  environment  = var.environment

  deletion_protection = var.deletion_protection
  password_min_length = var.password_min_length
  mfa_configuration   = var.mfa_configuration
}

module "api_gateway" {
  source = "./modules/api_gateway"

  project_name = var.project_name
  environment  = var.environment

  cognito_app_client_id = module.cognito.app_client_id
  cognito_issuer_url    = module.cognito.issuer_url

  cors_allowed_origins = var.cors_allowed_origins

  depends_on = [aws_api_gateway_account.this]
}
