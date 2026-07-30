output "document_uploaded_rule_arn" {
  value = module.document_uploaded_rule.arn
}

output "all_events_rule_arn" {
  value = module.all_events_rule.arn
}

output "document_uploads_log_group_name" {
  value = module.document_uploads_log.name
}

output "all_events_log_group_name" {
  value = module.all_events_log.name
}

output "document_uploaded_queue_arn" {
  value = aws_sqs_queue.document_uploaded.arn
}

output "document_uploaded_queue_url" {
  value = aws_sqs_queue.document_uploaded.url
}

output "document_uploaded_dlq_arn" {
  value = aws_sqs_queue.document_uploaded_dlq.arn
}

output "document_uploaded_dlq_url" {
  value = aws_sqs_queue.document_uploaded_dlq.url
}
