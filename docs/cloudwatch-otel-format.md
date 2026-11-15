# CloudWatch and OpenTelemetry format

CloudWatch supports OpenTelemetry-formatted telemetry through supported ingestion paths, but this is not an automatic conversion of AWS-native metrics. Native AWS metrics shared with OAM remain in their AWS namespaces and are still used by cross-account alarms. Workload OTLP telemetry must be emitted by SDK instrumentation/ADOT and sent to a supported CloudWatch OTLP ingestion endpoint or exporter in the target region.

Use the mapping and normalizer in `docs/otel-format-and-attributes.md` and `scripts/normalize_otel_inventory.py`. Apply OTel resource attributes at the workload or collector; do not change AWS metric dimensions needed by alarms. Project-specific `aws.observability.*`, `aws.resource.*`, and allowlisted `aws.tag.*` values are custom attributes, not OTel semantic conventions.
