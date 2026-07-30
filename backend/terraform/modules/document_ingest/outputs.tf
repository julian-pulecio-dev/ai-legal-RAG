output "function_name" {
  value = module.lambda.function_name
}

output "function_arn" {
  value = module.lambda.arn
}

output "log_group_name" {
  value = module.lambda.log_group_name
}

output "scalable_errors_topic_arn" {
  value = aws_sns_topic.scalable_errors.arn
}
