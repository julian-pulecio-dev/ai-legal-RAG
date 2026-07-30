# Module "vector_storage_queue": SQS queue (+ DLQ) that document_ingest
# publishes embedded vectors to, and vector_storage consumes in batches to
# write into S3 Vectors. Kept separate from both Lambda modules since
# neither one owns it end-to-end (one produces, the other consumes).

resource "aws_sqs_queue" "vector_storage_dlq" {
  name = "${var.project_name}-${var.environment}-vector-storage-dlq"

  visibility_timeout_seconds = 180

  tags = var.tags
}

# Visibility timeout is 6x vector_storage's Lambda timeout (AWS's
# recommendation) so a batch that's still processing doesn't become visible
# again and get picked up by a second, overlapping invocation.
resource "aws_sqs_queue" "vector_storage" {
  name = "${var.project_name}-${var.environment}-vector-storage"

  visibility_timeout_seconds = 360

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.vector_storage_dlq.arn
    maxReceiveCount     = 3
  })

  tags = var.tags
}
