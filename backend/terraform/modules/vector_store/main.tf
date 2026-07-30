# Module "vector_store": S3 Vectors bucket + index that back the Bedrock
# Knowledge Base's vector store. Kept separate from the knowledge_base
# module so the vector store's lifecycle isn't tied to the KB resource
# that references it.

resource "aws_s3vectors_vector_bucket" "this" {
  vector_bucket_name = "${var.project_name}-${var.environment}-vectors"

  tags = var.tags
}

resource "aws_s3vectors_index" "this" {
  index_name         = "${var.project_name}-${var.environment}-documents"
  vector_bucket_name = aws_s3vectors_vector_bucket.this.vector_bucket_name

  data_type       = "float32"
  dimension       = var.dimension
  distance_metric = var.distance_metric

  tags = var.tags
}
