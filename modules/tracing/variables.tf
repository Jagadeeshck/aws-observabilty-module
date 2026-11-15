variable "enable_xray_tracing" {
  description = "Opt in to enabling native X-Ray tracing on explicitly listed supported resources. This controller only enables tracing; it never disables it."
  type        = bool
  default     = false
}

variable "xray_tracing_services" {
  description = "Per-service opt-in for native X-Ray tracing. Supported controller actions: lambda, apigateway_rest, stepfunctions."
  type        = map(bool)
  default     = {
    lambda         = false
    apigateway_rest = false
    stepfunctions  = false
  }
  validation {
    condition     = alltrue([for service in keys(var.xray_tracing_services) : contains(["lambda", "apigateway_rest", "stepfunctions"], service)])
    error_message = "Native X-Ray tracing supports only lambda, apigateway_rest, and stepfunctions in this controller."
  }
}

variable "native_xray_resources" {
  description = "Explicitly allowlisted resource identifiers. Lambda and Step Functions entries use resource_arn; API Gateway REST entries use rest_api_id and stage_name."
  type = object({
    lambda = optional(map(string), {})
    apigateway_rest = optional(map(object({
      rest_api_id = string
      stage_name  = string
      region      = string
    })), {})
    stepfunctions = optional(map(string), {})
  })
  default = {}
}

variable "enable_otel_export" {
  description = "Enable the OTel/ADOT export path for selected application workloads. This exposes gates for workload deployment; it cannot instrument arbitrary AWS-managed resources."
  type        = bool
  default     = false
}

variable "otel_export_services" {
  description = "Per-service workload opt-in for OTel/ADOT export. These are configuration gates for workload-owned Terraform, not native AWS tracing toggles."
  type        = map(bool)
  default     = {}
}

variable "name" {
  description = "Name prefix for the scheduled native X-Ray enablement controller."
  type        = string
  default     = "observability-xray-enabler"
}

variable "schedule_expression" {
  description = "Schedule for idempotent reconciliation of explicitly opted-in native tracing settings."
  type        = string
  default     = "rate(1 day)"
}

variable "tags" {
  description = "Tags for controller resources."
  type        = map(string)
  default     = {}
}
