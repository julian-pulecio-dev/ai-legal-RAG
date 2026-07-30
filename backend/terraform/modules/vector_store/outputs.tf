output "vector_bucket_name" {
  value = aws_s3vectors_vector_bucket.this.vector_bucket_name
}

output "vector_bucket_arn" {
  value = aws_s3vectors_vector_bucket.this.vector_bucket_arn
}

output "index_name" {
  value = aws_s3vectors_index.this.index_name
}

output "index_arn" {
  value = aws_s3vectors_index.this.index_arn
}
