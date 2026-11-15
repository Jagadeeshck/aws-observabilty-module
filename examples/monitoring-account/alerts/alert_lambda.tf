# Lambda errors are an example of a native, per-function CloudWatch metric.
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = var.enable_alerts ? { for key, resource in try(var.resource_inventory.lambda, {}) : key => resource } : {}
  alarm_name = "${each.key}-lambda-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 1
  threshold = 1
  treat_missing_data = "notBreaching"
  alarm_actions = []
  metric_query {
    id = "m1"
    return_data = true
    metric {
      namespace = "AWS/Lambda"
      metric_name = "Errors"
      period = 300
      stat = "Sum"
      dimensions = each.value.dimensions
      account_id = try(each.value.account_id, var.source_account_id)
      region = try(each.value.region, var.source_region)
    }
  }
}
