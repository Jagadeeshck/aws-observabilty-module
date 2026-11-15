variable "resource_inventory" { type = any default = {} }
variable "alarm_actions" { type = list(string) default = [] }
variable "ok_actions" { type = list(string) default = [] }
variable "tags" { type = map(string) default = {} }
locals {
  alarm_specs = flatten([for resource_key, resource in var.resource_inventory : [for alarm in try(resource.alarms, []) : { key = "${resource_key}/${alarm.name}", dimensions = merge(try(resource.dimensions, {}), try(alarm.dimensions, {})), account_id = try(resource.account_id, null), region = try(resource.region, null), alarm = alarm }]])
  alarms = { for item in local.alarm_specs : item.key => item }
}
resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = local.alarms
  alarm_name = each.value.alarm.name
  alarm_description = try(each.value.alarm.description, null)
  comparison_operator = each.value.alarm.comparison_operator
  evaluation_periods = each.value.alarm.evaluation_periods
  threshold = each.value.alarm.threshold
  treat_missing_data = try(each.value.alarm.treat_missing_data, "missing")
  alarm_actions = var.alarm_actions
  ok_actions = var.ok_actions
  tags = var.tags
  metric_query {
    id = "m1"
    return_data = true
    metric {
      namespace = each.value.alarm.namespace
      metric_name = each.value.alarm.metric_name
      dimensions = each.value.dimensions
      period = each.value.alarm.period
      stat = each.value.alarm.statistic
      account_id = each.value.account_id
      region = each.value.region
      unit = try(each.value.alarm.unit, null)
    }
  }
}
