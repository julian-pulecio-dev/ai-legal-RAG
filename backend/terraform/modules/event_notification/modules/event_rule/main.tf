resource "aws_cloudwatch_event_rule" "this" {
  name          = var.name
  description   = var.description
  event_pattern = var.event_pattern

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "logs" {
  rule = aws_cloudwatch_event_rule.this.name
  arn  = var.log_group_arn
}
