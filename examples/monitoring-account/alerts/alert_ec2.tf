# Default EC2 status-check alarm in the monitoring account. The module also generates this baseline from inventory.
resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
  for_each = var.enable_alerts ? { for key, resource in try(var.resource_inventory.ec2, {}) : key => resource } : {}
  alarm_name = "${each.key}-ec2-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  threshold = 0
  treat_missing_data = "notBreaching"
  alarm_actions = []
  metric_query {
    id = "m1"
    return_data = true
    metric {
      namespace = "AWS/EC2"
      metric_name = "StatusCheckFailed"
      period = 300
      stat = "Maximum"
      dimensions = each.value.dimensions
      account_id = try(each.value.account_id, var.source_account_id)
      region = try(each.value.region, var.source_region)
    }
  }
}
