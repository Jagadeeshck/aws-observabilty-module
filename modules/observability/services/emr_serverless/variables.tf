variable "resource_inventory" {
  description = "Map of resource keys to {dimensions = map(string), alarms = list(object)}. Alarm fields: name, namespace, metric_name, statistic, period, evaluation_periods, threshold, comparison_operator, treat_missing_data, description."
  type        = any
  default     = {}
}
variable "alarm_actions" { type = list(string) default = [] }
variable "ok_actions" { type = list(string) default = [] }
variable "tags" { type = map(string) default = {} }
