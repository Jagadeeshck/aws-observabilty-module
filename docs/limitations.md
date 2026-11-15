# Current limitations and integration boundaries

- `scope = "all"` means all service modules in `supported_services`, not every AWS resource type.
- AWS Config is inventory, not a universal real-time discovery system. It only returns recorded/supported resources; newly created resources may not be visible immediately.
- The discovery script emits safe baseline alarms for a small set of stable metric/dimension combinations. It does not invent metrics for services that publish no per-resource metric.
- OAM shares eligible CloudWatch telemetry but does not transport OTLP traces. ADOT instrumentation is application/runtime-specific.
- IAM observability should generally use CloudTrail/EventBridge rules and log metric filters; Route 53, S3 Tables, Athena, Glue and DataZone alarm choices need service-specific metric/dimension validation.
- No module intentionally deletes or disables existing external monitoring. Terraform can delete resources in its own state when inventory/config entries are removed.
