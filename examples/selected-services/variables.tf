variable "enabled" { type = bool default = false }
variable "scope" { type = string default = "selected" }
variable "services" {
  type = set(string)
  default = ["lambda", "rds", "bedrock", "sagemaker", "agentcore"]
}
variable "resource_inventory" { type = any default = {} }
variable "alarm_actions" { type = list(string) default = [] }
variable "ok_actions" { type = list(string) default = [] }
variable "tags" { type = map(string) default = {} }
