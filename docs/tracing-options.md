# Tracing supports two independently controlled options:
# - enable_xray_tracing + xray_tracing_services: native, explicit resource toggles
# - enable_otel_export + otel_export_services: output gates for instrumented workloads
# Native X-Ray currently supports Lambda, API Gateway REST stages, and Step Functions.
# OTel/ADOT export still requires app instrumentation and collector configuration.
