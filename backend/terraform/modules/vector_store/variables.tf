variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "dimension" {
  description = "Embedding vector size. Must match the knowledge base's embedding model configuration."
  type        = number
  default     = 1024
}

variable "distance_metric" {
  description = "Similarity metric for the vector index: cosine or euclidean."
  type        = string
  default     = "cosine"
}

variable "tags" {
  type    = map(string)
  default = {}
}
