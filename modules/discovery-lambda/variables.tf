variable "enabled" {
  description = "Whether to deploy the discovery Lambda."
  type        = bool
  default     = false
}

variable "name" {
  description = "Logical name for the discovery Lambda and related resources."
  type        = string
  default     = "aws-observability-discovery"
}

variable "schedule_expression" {
  description = "CloudWatch Events cron schedule expression for regular discovery runs."
  type        = string
  default     = "rate(1 hour)"
}

variable "services" {
  description = "AWS services to inventory. Discovery Lambda can inspect these service types.
  This is for reporting and optional enablement, not a universal AWS scan."
  type = list(string)
  default = ["ec2", "rds", "lambda", "ecs", "emr", "dynamodb", "s3", "opensearch", "athena", "glue", "route53", "sagemaker", "bedrock", "agentcore"]
}

variable "report_bucket_name" {
  description = "Optional S3 bucket to store discovery JSON reports. Leave null to emit only CloudWatch logs."
  type        = string
  default     = null
}

variable "report_topic_arn" {
  description = "Optional SNS topic ARN for discovery reports."
  type        = string
  default     = null
}

variable "report_s3_prefix" {
  description = "Prefix used for S3 reports."
  type        = string
  default     = "aws-observability-discovery/"
}

variable "enable_observability" {
  description = "If true, the lambda can attempt supported service-specific opt-in actions (for example Lambda tracing and EC2 detailed monitoring)."
  type        = bool
  default     = false
}

variable "observability_service_settings" {
  description = "Explicit per-service observability settings that may be enabled by the discovery Lambda. Only supported service settings are acted on."
  type = map(object({
    enabled              = bool
    tracing_mode         = optional(string)
    detailed_monitoring  = optional(bool)
    logs_retention_days  = optional(number)
    performance_insights = optional(bool)
  }))
  default = {}
}

variable "lambda_runtime" {
  description = "Runtime for the discovery Lambda."
  type        = string
  default     = "python3.12"
}

variable "lambda_memory_size" {
  description = "Memory size for the discovery Lambda."
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Timeout in seconds for the discovery Lambda."
  type        = number
  default     = 300
}

variable "tags" {
  description = "Tags applied to discovery resources."
  type        = map(string)
  default     = {}
}
