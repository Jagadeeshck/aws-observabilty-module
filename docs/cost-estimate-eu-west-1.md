# CloudWatch cost model for eu-west-1 (Ireland)

## Important

CloudWatch cost depends on telemetry volume, metric cardinality, retention, alarm count, query/scan volume, and export/transfer. There is no meaningful single fixed price for this Terraform module. The figures below are **planning estimates, not a quote**; AWS prices, tiers, free tiers, and feature availability change. Confirm current `EU (Ireland)` rates in the [official CloudWatch pricing page](https://aws.amazon.com/cloudwatch/pricing/) and model your actual workload in the [AWS Pricing Calculator](https://calculator.aws/).

OAM links/sinks do not themselves turn on instrumentation. Cross-account OAM charges, if applicable, are based on the underlying CloudWatch usage and AWS's current pricing rules. Confirm current OAM treatment on the pricing page. AWS Config, Lambda, EventBridge, S3, SNS, data transfer, and any ADOT compute are separate line items and are not included in the simple example below.

## Estimate inputs

Use the following variables for a first estimate:

- `A`: number of standard-resolution alarms in the monitoring account
- `M`: billable custom/OTel metric volume and dimensions, using the billing unit/rate shown for the selected CloudWatch ingestion path
- `L_ingest`: GB of logs ingested each month
- `L_store`: average GB of retained logs per month
- `T`: number of trace spans/documents ingested each month (check the relevant X-Ray/OTel pricing unit; spans are not necessarily equivalent to end-to-end traces)
- `Q`: dashboards, metric queries, Logs Insights scans, exports, and other metered operations

Illustrative arithmetic using approximate public list-price magnitudes sometimes seen for eu-west-1—**verify before budgeting**:

| Cost item | Example quantity | Approximate unit assumption | Rough monthly amount |
|---|---:|---:|---:|
| Standard alarms | 25 alarms | $0.10/alarm-month | $2.50 |
| Log ingestion | 10 GB | $0.49/GB | $4.90 |
| Log storage | 10 GB-month average | $0.03/GB-month | $0.30 |
| OTel metrics ingestion | 1 GB | $0.90/GB | $0.90 |
| Trace ingestion | 1 million trace documents | $5/million | $5.00 |
| **Illustrative subtotal** |  |  | **$13.60/month** |

This subtotal is **not a complete deployment estimate** and these unit assumptions may not match the currently applicable CloudWatch OTLP, metrics, Logs, or X-Ray price dimensions in Ireland. Do not assume native AWS service metrics are charged like custom metrics, or that OTLP data is billed by the same unit as EMF/custom metrics. Check the exact billing dimension and regional price before multiplying.

## Costs commonly omitted from the subtotal

- AWS Config recorder, aggregator, configuration items, queries, and delivery storage
- Discovery Lambda invocations, duration, and CloudWatch logs
- EventBridge schedule, S3 report storage/requests, SNS notifications
- ADOT Collector compute (ECS/Fargate, EKS, EC2) and load balancer/NAT/VPC endpoints
- X-Ray trace retrieval/analysis or CloudWatch trace features, where applicable
- CloudWatch dashboards, metric streams, Logs Insights scans, exports, and cross-region transfer
- Optional detailed monitoring, Performance Insights/Database Insights, S3 request metrics, and other service-specific enhanced telemetry
- Alarm action destination costs and cross-account/region data transfer

## How to get a defensible estimate

1. Select the eu-west-1 location and the exact CloudWatch features in AWS Pricing Calculator.
2. Estimate custom metric series/cardinality and OTLP data volume from a representative test; do not use resource count alone.
3. Measure average log bytes/day and retention in days. Keep high-cardinality IDs out of metric labels.
4. Estimate spans/documents per request and sample rate, then verify the applicable trace billing unit.
5. Count alarms after inventory expansion; alarm-per-resource designs can grow quickly.
6. Add Config, Lambda, collector compute, networking, storage, and data-transfer line items.
7. Use Cost Explorer and AWS Budgets after a pilot; set alarms for spend.

See the module's actual inventory and selected alert templates before forecasting: default alarms are created only when `enable_alerts = true`, and only for supported resources with valid metric dimensions. Optional source-side telemetry can incur additional AWS charges.
