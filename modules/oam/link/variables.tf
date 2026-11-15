variable "sink_identifier" {
  description = "OAM sink ARN or ID in the monitoring account."
  type        = string
}
variable "label" {
  description = "Human-readable label for this source-account link."
  type        = string
}
variable "resource_types" {
  description = "Telemetry resource types to share with the monitoring account."
  type        = list(string)
  default     = ["AWS::CloudWatch::Metric", "AWS::Logs::LogGroup"]
}
variable "tags" {
  type    = map(string)
  default = {}
}
