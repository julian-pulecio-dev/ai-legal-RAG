output "arn" {
  value = aws_lambda_layer_version.this.arn
}

output "layer_name" {
  value = aws_lambda_layer_version.this.layer_name
}
