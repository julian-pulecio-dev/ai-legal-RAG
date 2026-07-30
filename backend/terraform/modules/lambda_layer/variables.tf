variable "name" {
  type = string
}

variable "source_dir" {
  description = "Path to the layer's root directory (must contain a top-level python/ folder)."
  type        = string
}

variable "compatible_runtimes" {
  type    = list(string)
  default = ["python3.13"]
}
