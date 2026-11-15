# Bedrock aggregate runtime metrics can be alarmed without a resource-specific dimension; validate actual publication in the source region.
resource "aws_cloudwatch_metric_alarm" "bedrock_server_errors" {
  count = var.enable_alerts ? 1 : 0
  alarm_name = "bedrock-server-errors-${var.source_account_id}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 1
  threshold = 1
  treat_missing_data = "notBreaching"
  alarm_actions = []
  metric_query {
    id = "m1"
    return_data = true
    metric {
      namespace = "AWS/Bedrock"
      metric_name = "InvocationServerErrors"
      period = 300
      stat = "Sum"
      dimensions = {}
      account_id = var.source_account_id
      region = var.source_region
    }
  }
}
