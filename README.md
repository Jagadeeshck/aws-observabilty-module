# AWS observability Terraform modules

Reusable Terraform modules for inventory-driven CloudWatch alarms, cross-account monitoring, and workload tracing in AWS.

## Modules

- `modules/observability/` — CloudWatch alarms configured from service inventory.
- `modules/otel-gateway/` — ADOT collector gateway scaffolding.
- `modules/tracing/` — separate controls for native X-Ray settings and OTel/ADOT workload export.

Examples are under `examples/`; implementation guidance and service limitations are in `docs/`.

## Quick start: selected services and alarms

Apply alarm resources in the monitoring account. For cross-account metrics, configure OAM sharing from workload accounts and include the source account and region in inventory as required by the alarm module.

```hcl
module "observability" {
  source = "./modules/observability"

  enabled       = true
  enable_alerts = true
  scope         = "selected"
  services      = ["emr_serverless"]

  resource_inventory = {
    emr_serverless = {
      spark_app_job = {
        dimensions = {
          ApplicationId = "00fexampleapp"
          JobId         = "00fexamplejob"
          WorkerType    = "Spark-Driver"
        }
        alarms = [{
          name                = "spark-driver-cpu-used"
          namespace           = "AWS/EMRServerless"
          metric_name         = "WorkerCpuUsed"
          statistic           = "Maximum"
          period              = 300
          evaluation_periods  = 3
          threshold           = 4
          comparison_operator = "GreaterThanThreshold"
          treat_missing_data  = "notBreaching"
        }]
      }
    }
  }
}
```

This is an inventory-driven alarm example; replace the example IDs, worker dimension, threshold, and alarm name with values appropriate to your workload and the metrics actually published in your Region. EMR Serverless worker metric units are resource quantities (for example, vCPU or GB), not percentages. Job IDs change between runs, so a job-specific alarm is useful only when the job run ID is known and the metric is being emitted. See [EMR Serverless observability guidance](docs/emr-serverless-observability.md) for metric, event, and log boundaries.

## Tracing controls

Tracing has two distinct approaches:

- **Native X-Ray:** `modules/tracing/` supports explicit allowlisting for Lambda functions, API Gateway REST stages, and Step Functions state machines.
- **OTel/ADOT:** workload export gates identify services to configure, but application code, SDKs/layers, collectors, and exporters still need to be instrumented and configured.

Tracing setup belongs with workload deployments; monitoring and alarm aggregation commonly belongs in the monitoring account. See [`modules/tracing/README.md`](modules/tracing/README.md).

## Important boundaries

- CloudWatch metrics cover resource usage; EMR Serverless job state transitions are EventBridge events, not assumed CloudWatch count metrics.
- Spark event logs and the Spark UI provide execution-level diagnostics; configure log destinations for your applications and jobs.
- Inventory/discovery does not automatically instrument workloads.
- Review Terraform plans, metric dimensions, IAM permissions, regional support, and AWS costs before applying.
