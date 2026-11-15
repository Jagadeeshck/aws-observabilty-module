# OpenTelemetry format, semantic attributes, and CloudWatch

## Short answer

CloudWatch can receive and work with OpenTelemetry-formatted telemetry through supported OpenTelemetry ingestion paths. This does **not** automatically convert every native AWS service metric or OAM-shared metric into OTLP, nor does choosing an OpenTelemetry format automatically add every semantic-convention attribute. The workload or collector must emit OTLP and attach resource attributes.

Keep two paths distinct:

1. **AWS-native metrics and alarms:** EC2, RDS, Lambda, and other AWS services publish metrics in their CloudWatch namespaces. OAM shares eligible telemetry. Cross-account alarms in the monitoring account continue to query the original namespace, dimensions, source `account_id`, and `region`.
2. **OTel application telemetry:** instrumented workloads and the ADOT Collector produce OTLP metrics/traces/logs. Where the CloudWatch OTLP ingestion feature is available and enabled in the target account/region, use its documented endpoint and authentication. Otherwise, use a supported ADOT exporter/destination. Do not assume OAM is an OTLP receiver.

Confirm the current feature availability, endpoint, supported signals, limits, and pricing in AWS documentation for `eu-west-1` before enabling a production pipeline. Terraform provider support for a feature-specific CloudWatch setting may lag the service API; use the documented AWS API/collector configuration rather than inventing a Terraform argument.

## Resource attribute policy

Use stable OpenTelemetry semantic-convention resource attributes where applicable:

| Attribute | Use |
|---|---|
| `cloud.provider` | `aws` |
| `cloud.account.id` | AWS account that owns the workload/resource |
| `cloud.region` | Resource region |
| `cloud.availability_zone` | When known for a zonal resource |
| `cloud.platform` | Only when a documented platform value applies (for example, AWS Lambda) |
| `service.name` | Workload/service name when known; do not infer it from an arbitrary AWS resource name |
| `service.namespace` | Owning application or team namespace when supplied |
| `deployment.environment.name` | Environment when supplied by the deployment/inventory |
| `host.id` | Host/instance identity for host telemetry when applicable |

Use a documented project namespace for AWS inventory attributes not covered by stable OTel conventions. In this repository, the prefix `aws.observability.*` is project-defined, not an OTel standard:

- `aws.resource.id`
- `aws.resource.type`
- `aws.observability.metrics.enabled`
- `aws.observability.logs.enabled`
- `aws.observability.tracing.enabled`
- `aws.observability.detailed_monitoring.enabled`
- `aws.observability.source` (for example, `aws-config`)

Resource tags are arbitrary customer data. Map only an allowlist into attributes such as `aws.tag.<key>`; avoid exporting secrets, personal data, or unbounded/high-cardinality tags. Do not call custom attributes semantic conventions.

## Inventory normalization

`scripts/normalize_otel_inventory.py` converts a resource inventory JSON list into a report with OTel resource attribute maps. It does not create telemetry or modify AWS resources. Unknown fields are retained under the custom `aws.*` namespace rather than mislabeled as standard conventions. Run the unit tests with:

```sh
python -m unittest discover -s tests -v
python scripts/normalize_otel_inventory.py --input examples/otel/resource-inventory.json --output /tmp/otel-inventory.json
```

## Collector integration

Instrument the application with an OpenTelemetry SDK or supported auto-instrumentation, set resource attributes at the source, then send OTLP to a private, authenticated ADOT Collector endpoint. The collector can add missing stable context only when that context is known (for example, account and region from AWS resource detection), batch and export signals, and preserve custom attributes. Verify the configured exporter and destination support the signal and OTLP version you use.

A collector cannot infer service ownership, environment, or meaningful traces from arbitrary AWS resources. No spans are produced for a managed service merely because OAM is linked. For Lambda, use the supported runtime-specific ADOT layer/wrapper or SDK; for ECS/EKS/EC2, instrument the application and configure an exporter.

## References

- [CloudWatch OpenTelemetry metrics overview](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/metrics-otel-overview.html)
- [CloudWatch cross-account observability](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Cross-Account-Cross-Region.html)
- [OpenTelemetry semantic conventions](https://opentelemetry.io/docs/specs/semconv/)
- [OpenTelemetry AWS resource detector](https://opentelemetry.io/docs/specs/semconv/resource/cloud/)
