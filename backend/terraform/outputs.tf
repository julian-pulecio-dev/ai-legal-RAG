output "cognito_user_pool_id" {
  value = module.cognito.user_pool_id
}

output "cognito_app_client_id" {
  value = module.cognito.app_client_id
}

output "cognito_issuer_url" {
  value = module.cognito.issuer_url
}

output "api_endpoint" {
  value = module.api_gateway.api_endpoint
}

output "aws_region" {
  value = var.aws_region
}

output "documents_bucket_id" {
  value = module.documents_bucket.id
}

output "documents_bucket_arn" {
  value = module.documents_bucket.arn
}

output "document_uploaded_rule_arn" {
  value = module.event_notification.document_uploaded_rule_arn
}

output "all_events_rule_arn" {
  value = module.event_notification.all_events_rule_arn
}

output "document_uploads_log_group_name" {
  value = module.event_notification.document_uploads_log_group_name
}

output "all_events_log_group_name" {
  value = module.event_notification.all_events_log_group_name
}

output "document_uploaded_queue_arn" {
  value = module.event_notification.document_uploaded_queue_arn
}

output "document_uploaded_queue_url" {
  value = module.event_notification.document_uploaded_queue_url
}

output "document_uploaded_dlq_arn" {
  value = module.event_notification.document_uploaded_dlq_arn
}

output "document_uploaded_dlq_url" {
  value = module.event_notification.document_uploaded_dlq_url
}

output "document_ingest_function_name" {
  value = module.document_ingest.function_name
}

output "document_ingest_function_arn" {
  value = module.document_ingest.function_arn
}

output "document_ingest_scalable_errors_topic_arn" {
  value = module.document_ingest.scalable_errors_topic_arn
}

output "dlq_notifier_function_name" {
  value = module.dlq_notifier.function_name
}

output "dlq_notifier_function_arn" {
  value = module.dlq_notifier.function_arn
}

output "dlq_notifications_topic_arn" {
  value = module.dlq_notifier.dlq_notifications_topic_arn
}

output "vector_bucket_name" {
  value = module.vector_store.vector_bucket_name
}

output "vector_index_arn" {
  value = module.vector_store.index_arn
}

output "vector_storage_queue_arn" {
  value = module.vector_storage_queue.queue_arn
}

output "vector_storage_queue_url" {
  value = module.vector_storage_queue.queue_url
}

output "vector_storage_dlq_arn" {
  value = module.vector_storage_queue.dlq_arn
}

output "vector_storage_dlq_url" {
  value = module.vector_storage_queue.dlq_url
}

output "vector_storage_function_name" {
  value = module.vector_storage.function_name
}

output "vector_storage_function_arn" {
  value = module.vector_storage.function_arn
}

output "vector_storage_scalable_errors_topic_arn" {
  value = module.vector_storage.scalable_errors_topic_arn
}
