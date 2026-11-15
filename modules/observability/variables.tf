variable "enabled" {
  description = "Master module switch. False creates no observability resources."
  type        = bool
  default     = true
}
variable "enable_alerts" {
  description = "Create baseline and inventory-provided custom CloudWatch alarms."
  type        = bool
  default     = false
}
variable "scope" {
  description = "all enables every supported service type; selected uses services."
  type        = string
  default     = "selected"
  validation { condition = contains(["all", "selected"], var.scope) error_message = "scope must be all or selected." }
}
variable "services" {
  description = "Supported service keys to monitor when scope=selected."
  type        = set(string)
  default     = []
  validation {
    condition = alltrue([for service in var.services : contains(["ec2", "rds", "ecs", "lambda", "emr", "emr_serverless", "sagemaker", "bedrock", "agentcore", "s3", "s3_tables", "athena", "glue", "datazone", "dynamodb", "opensearch", "iam", "route53"], service)])
    error_message = "services contains an unsupported service key."
  }
}
variable "resource_inventory" {
  description = "Inventory keyed by service then resource key. Each resource has dimensions, optional source account_id/region, and optional alarms list."
  type        = any
  default     = {}
}
variable "alarm_actions" { description = "Alarm action ARNs in the account applying this module (normally monitoring account)." type = list(string) default = [] }
variable "ok_actions" { type = list(string) default = [] }
variable "tags" { type = map(string) default = {} }
