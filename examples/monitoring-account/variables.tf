variable "monitoring_region" { type = string default = "us-east-1" }
variable "resource_inventory" { type = any default = {} }
variable "source_account_id" { type = string }
variable "source_region" { type = string default = "us-east-1" }
variable "enable_alerts" { type = bool default = true }
