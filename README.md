# AWS observability Terraform module

This repository provides inventory-driven CloudWatch alarms, OAM cross-account sharing examples, discovery tooling, and ADOT/OpenTelemetry guidance.

- Set `enable_alerts = true` to create baseline and custom alarms in the account where the alarm module is applied (typically the monitoring account).
- OAM shares supported source-account telemetry; cross-account alarms query source metrics by account and region.
- Inventory and workload instrumentation are separate: AWS Config/discovery reports resources, while OTLP telemetry requires an instrumented workload or supported AWS integration.
- The CloudWatch OpenTelemetry format and resource attribute mapping are described in [`docs/otel-format-and-attributes.md`](docs/otel-format-and-attributes.md).
- Cost planning for `eu-west-1` is in [`docs/cost-estimate-eu-west-1.md`](docs/cost-estimate-eu-west-1.md). Cost examples are estimates; verify rates in AWS Pricing Calculator.

See `docs/cloudwatch-otel-format.md`, `docs/inventory-and-tracing.md`, and `docs/limitations.md` for implementation boundaries. Custom `aws.*` inventory attributes are clearly distinguished from standard OpenTelemetry semantic conventions.
