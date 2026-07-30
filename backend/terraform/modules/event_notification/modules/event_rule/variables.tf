variable "name" {
  type = string
}

variable "description" {
  type    = string
  default = null
}

variable "event_pattern" {
  description = "JSON event pattern (jsonencode) that filters which events trigger this rule."
  type        = string
}

variable "log_group_arn" {
  description = "ARN of the CloudWatch log group this rule sends matched events to."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
