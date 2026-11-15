variable "enabled" {
  description = "Master switch. False creates no alarms."
  type        = bool
  default     = false
}

variable "scope" {
  description = "all enables every service supported by this module; selected uses services."
  type        = string
  default     = "selected"
  validation {
    condition     = contains(["all", "selected"], var.scope)
    error_message = "scope must be all or selected."
  }
}

variable "services" {
  description = "Supported service keys to monitor when scope is selected."
  type        = set(string)
  default     = []
  validation {
    condition = alltrue([for service in var.services : contains(["ec2", "rds", "ecs", "lambda", "emr", "sagemaker", "bedrock", "agentcore"], service)])
    error_message = "services contains an unsupported service key. See README for supported services."
  }
}

variable "resource_inventory" {
  description = "Inventory keyed by service then stable resource key. Each resource has dimensions (map) and alarms (list of metric alarm specs). Populate this from an external inventory/discovery process."
  type        = any
  default     = {}
}

variable "alarm_actions" {
  description = "CloudWatch alarm action ARNs, typically an SNS topic in the monitoring account."
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "CloudWatch alarm OK action ARNs."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to alarms."
  type        = map(string)
  default     = {}
}
