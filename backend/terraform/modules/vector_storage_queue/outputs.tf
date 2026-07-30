output "queue_arn" {
  value = aws_sqs_queue.vector_storage.arn
}

output "queue_url" {
  value = aws_sqs_queue.vector_storage.url
}

output "dlq_arn" {
  value = aws_sqs_queue.vector_storage_dlq.arn
}

output "dlq_url" {
  value = aws_sqs_queue.vector_storage_dlq.url
}
