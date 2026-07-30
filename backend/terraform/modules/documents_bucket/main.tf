# Module "documents_bucket": private S3 bucket for the legal documents that
# feed the RAG pipeline (ingestion, embeddings, etc.).

resource "aws_s3_bucket" "this" {
  bucket        = "${var.project_name}-${var.environment}-documents"
  force_destroy = var.force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Sends every bucket event (ObjectCreated, ObjectRemoved, etc.) to the
# default EventBridge event bus so we can react to them (for example,
# triggering ingestion of a newly uploaded document).
resource "aws_s3_bucket_notification" "eventbridge" {
  bucket      = aws_s3_bucket.this.id
  eventbridge = true
}
