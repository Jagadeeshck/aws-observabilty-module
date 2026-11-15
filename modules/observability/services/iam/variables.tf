variable "resource_inventory" {
  description = "IAM inventory is for security event observability. Metric alarms require CloudTrail/EventBridge metric filters or custom metrics and must be specified explicitly."
  type        = any
  default     = {}
}
variable "alarm_actions" { type = list(string) default = [] }
variable "ok_actions" { type = list(string) default = [] }
variable "tags" { type = map(string) default = {} }
