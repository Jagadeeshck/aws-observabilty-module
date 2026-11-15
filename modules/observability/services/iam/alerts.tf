# IAM has no general-purpose CloudWatch metric namespace. Feed alarms here only after creating supported CloudTrail/EventBridge metric filters or publishing custom metrics.
resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = local.alarms
  alarm_name = each.value.alarm.name
  alarm_description = try(each.value.alarm.description, null)
  comparison_operator = each.value.alarm.comparison_operator
  evaluation_periods = each.value.alarm.evaluation_periods
  metric_name = each.value.alarm.metric_name
  namespace = each.value.alarm.namespace
  period = each.value.alarm.period
  statistic = each.value.alarm.statistic
  threshold = each.value.alarm.threshold
  dimensions = each.value.dimensions
  treat_missing_data = try(each.value.alarm.treat_missing_data, "missing")
  alarm_actions = var.alarm_actions
  ok_actions = var.ok_actions
  tags = var.tags
}
