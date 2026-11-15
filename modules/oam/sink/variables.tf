variable "name" {
  description = "OAM sink name in the monitoring account."
  type        = string
}
variable "allowed_account_ids" {
  description = "Source account IDs allowed to create links. Use an organization policy instead for large organizations."
  type        = list(string)
  default     = []
}
variable "organization_id" {
  description = "Optional AWS Organizations ID to authorize instead of explicit account IDs."
  type        = string
  default     = null
}
variable "resource_types" {
  description = "Telemetry resource types shared by links."
  type        = list(string)
  default     = ["AWS::CloudWatch::Metric", "AWS::Logs::LogGroup"]
}
