# Module "lambda_function": generic Lambda function with its own log group.
# It doesn't know about SQS, use-case-specific IAM, or code packaging (that's
# handled by the module that instantiates it alongside "lambda_package").

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = var.role_arn

  filename         = var.filename
  source_code_hash = var.source_code_hash

  handler = var.handler
  runtime = var.runtime

  timeout     = var.timeout
  memory_size = var.memory_size

  layers = var.layers

  environment {
    variables = var.environment_variables
  }

  logging_config {
    log_group  = aws_cloudwatch_log_group.this.name
    log_format = "Text"
  }

  tags = var.tags

  depends_on = [aws_cloudwatch_log_group.this]
}
