# Example standalone alert file. Add resource-specific metrics only after confirming they are emitted and shared via OAM.
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  for_each = var.enable_alerts ? { for key, resource in try(var.resource_inventory.rds, {}) : key => resource } : {}
  alarm_name = "${each.key}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  threshold = 80
  treat_missing_data = "missing"
  alarm_actions = []
  metric_query {
    id = "m1"
    return_data = true
    metric {
      namespace = "AWS/RDS"
      metric_name = "CPUUtilization"
      period = 300
      stat = "Average"
      dimensions = each.value.dimensions
      account_id = try(each.value.account_id, var.source_account_id)
      region = try(each.value.region, var.source_region)
    }
  }
}
