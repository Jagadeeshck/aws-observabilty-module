variable "resource_inventory" {
  description = "Resource keys mapped to dimensions and optional alarm specs. Metrics must be valid for the resource and region."
  type        = any
  default     = {}
}
variable "alarm_actions" { type = list(string) default = [] }
variable "ok_actions" { type = list(string) default = [] }
variable "tags" { type = map(string) default = {} }
