output "xray_controller_lambda_arn" {
  description = "Scheduled Lambda that enables native X-Ray only on explicitly listed supported resources when enable_xray_tracing is true."
  value       = aws_lambda_function.controller.arn
}

output "otel_export_enabled_services" {
  description = "Service keys whose workload-owned Terraform should configure ADOT/OTel export. This does not auto-instrument resources."
  value       = local.otel_export_enabled_services
}
