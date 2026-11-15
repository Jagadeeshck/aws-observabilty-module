# AgentCore metrics and trace/log emission are service- and feature-specific. Provide only dimensions and metrics published in the target account/region; OTLP trace setup is documented in the root README.
locals {
  alarm_specs = flatten([for resource_key, resource in var.resource_inventory : [for alarm in try(resource.alarms, []) : { key = "${resource_key}/${alarm.name}", dimensions = merge(try(resource.dimensions, {}), try(alarm.dimensions, {})), alarm = alarm }]])
  alarms = { for item in local.alarm_specs : item.key => item }
}
