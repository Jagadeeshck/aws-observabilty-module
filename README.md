# AWS observability Terraform modules

Reusable Terraform modules for inventory-driven CloudWatch alarms, cross-account telemetry sharing, and explicitly configured workload tracing in AWS.

> **Important:** This repository does not automatically enable observability for every resource in an AWS account. Alarm creation, OAM sharing, native X-Ray settings, and application instrumentation are separate, opt-in concerns. Review each module's scope and the Terraform plan before applying.

## What the repository provides

| Module | Purpose | What it does not do automatically |
| --- | --- | --- |
| [`modules/observability`](modules/observability/) | Creates CloudWatch metric alarms from inventory and alarm specifications. Supports service selection and monitoring-account cross-account metric queries. | Does not enable service logs, install agents, instrument applications, or create alarms for resources absent from inventory. Default alarms cover only explicitly defined, documented metric templates. |
| [`modules/oam/sink`](modules/oam/sink/) | Creates a CloudWatch Observability Access Manager (OAM) sink and access policy, normally in the monitoring account. | Does not collect telemetry or configure source accounts by itself. |
| [`modules/oam/link`](modules/oam/link/) | Links a workload/source account to an OAM sink and selects telemetry resource types to share. | Does not transport OTLP traces or enable tracing/instrumentation. |
| [`modules/tracing`](modules/tracing/) | Optionally enables native X-Ray settings for explicitly allowlisted Lambda, API Gateway REST stage, and Step Functions resources; exposes OTel service selection gates. | Does not trace every resource. OTel gates do not install SDKs/layers or instrument workloads. |
| [`modules/otel-gateway`](modules/otel-gateway/) | Scaffolds an ECS/Fargate ADOT collector gateway and related infrastructure. | Is not a turnkey collector pipeline; collector configuration delivery and the placeholder configuration storage must be completed before deployment. |

Runnable examples and supporting docs: [`examples/`](examples/) and [`docs/`](docs/).

## What “observability enabled” means here

The service modules under `modules/observability/services/` primarily define **CloudWatch alarms**. A service being listed as supported or selected does not mean that logs, tracing, enhanced metrics, or application instrumentation have been enabled.

- **Metrics and alarms:** AWS services may publish metrics without extra setup, but this module creates alarms only for inventoried resources and configured metric/dimension combinations.
- **Logs:** Configure the AWS service or workload to deliver logs to CloudWatch Logs or S3. OAM links can share eligible log groups; they do not create log delivery settings.
- **Tracing:** Use a supported native tracing setting or instrument the application with an appropriate SDK/ADOT path. These actions are distinct from alarm creation.
- **Events:** For state changes not published as CloudWatch metrics (for example, EMR Serverless job outcomes), configure EventBridge rules and targets. The alarm module does not create these automatically.
- **Cross-account visibility:** Create an OAM sink in the monitoring account and OAM links in source accounts for supported telemetry. Cross-account metric alarms also need the relevant source account and region in their inventory configuration.

## Getting started: monitoring and alarms

1. Choose the account where alarms should live (commonly a monitoring account) and configure AWS provider credentials and region.
2. Select supported service keys and provide resource inventory with the exact CloudWatch metric dimensions for your resources.
3. Set `enable_alerts = true` to create the alarms. `enabled = false` disables the observability module, and `scope = "all"` selects all service keys implemented by this version—not every AWS resource type.
4. Review the plan, especially dimensions, metric units, thresholds, missing-data behavior, alarm actions, cross-account source account/region, and expected costs.
5. Apply only after validating that the metrics exist in the target Region and the alarm dimensions match the published metric.

Example using an EC2 baseline alarm and an explicit custom alarm:

```hcl
module "observability" {
  source = "./modules/observability"

  enabled       = true
  enable_alerts = true
  scope         = "selected"
  services      = ["ec2", "emr_serverless"]
  alarm_actions = ["arn:aws:sns:eu-west-1:111122223333:ops-alerts"]

  resource_inventory = {
    ec2 = {
      web_instance = {
        dimensions = { InstanceId = "i-0123456789abcdef0" }
      }
    }
    emr_serverless = {
      spark_job = {
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

The EC2 resource receives the module's configured baseline alarm template. The EMR Serverless entry shows a custom alarm: replace placeholder identifiers and verify the metric's actual dimensions, unit, and threshold in AWS documentation and CloudWatch. Job-run identifiers are ephemeral, so job-specific metric alarms are best for known or actively tracked runs. EMR Serverless lifecycle notifications should use EventBridge, not assumed CloudWatch job-count metrics. See [EMR Serverless observability](docs/emr-serverless-observability.md).

### Default and advanced monitoring

**Default monitoring** means the baseline alarm templates implemented in `modules/observability/locals.tf`, applied to matching inventory entries when alarms are enabled. Templates are deliberately limited to known metric/dimension combinations; not every supported service has a default alarm. No inventory means no per-resource alarms.

**Advanced monitoring** currently means supplying additional per-resource `alarms` in `resource_inventory`. Each alarm defines its CloudWatch namespace, metric name, dimensions (on the resource or alarm), statistic, period, evaluation periods, threshold, comparison operator, and optional missing-data treatment/description. Validate metric units and dimensions yourself. Advanced logs, dashboards, EventBridge rules, and service-specific instrumentation must be configured by their owning workload or separate Terraform; they are not implicitly created by this module.

## Cross-account monitoring with OAM

Use the OAM sink in the monitoring account and an OAM link in each workload account. Configure provider aliases/assume-role access so each module is applied in the correct account and Region. Restrict sink access to the intended accounts or organization, and select only the resource types you want to share.

Illustrative module inputs:

```hcl
# Monitoring account
module "oam_sink" {
  source              = "./modules/oam/sink"
  name                = "central-observability"
  allowed_account_ids = ["444455556666"]
  resource_types      = ["AWS::CloudWatch::Metric", "AWS::Logs::LogGroup"]
}

# Workload account (configure this provider for the source account)
module "oam_link" {
  source         = "./modules/oam/link"
  sink_identifier = "arn:aws:oam:eu-west-1:111122223333:sink/example-sink-id"
  label           = "workload-prod"
  resource_types  = ["AWS::CloudWatch::Metric", "AWS::Logs::LogGroup"]
}
```

Use the actual sink ARN output from the monitoring-account deployment. OAM shares eligible CloudWatch telemetry; it does not configure service log delivery, create alarms in source accounts, or transport OTLP traces. See [`modules/oam/`](modules/oam/) and [`examples/monitoring-account/`](examples/monitoring-account/).

## Tracing and OTel/ADOT

### Native X-Ray

The tracing module's native controller is opt-in and operates only on the explicit resource allowlist. It currently supports Lambda functions, API Gateway REST API stages, and Step Functions state machines. Provide matching execution/service role ARNs for Lambda and Step Functions so those roles can publish trace data. Review [`modules/tracing/README.md`](modules/tracing/README.md) for permissions and limitations.

### OTel/ADOT

The OTel export selection is a signal for workload-owned Terraform, not an instrumentation switch. Applications still need suitable SDKs/auto-instrumentation, exporter configuration, network access, and a functioning collector. The gateway module is scaffolding only until its collector configuration and configuration-volume setup are supplied and validated. Start from [`examples/otel/`](examples/otel/) and read the module notes before deploying.

## Examples and further reading

- [`examples/monitoring-account/`](examples/monitoring-account/) — monitoring-account alarm deployment.
- [`examples/selected-services/`](examples/selected-services/) — selected service inventory.
- [`examples/emr-serverless/`](examples/emr-serverless/) — EMR Serverless/Spark metric alarm example.
- [`examples/tracing/`](examples/tracing/) — native X-Ray and OTel gates.
- [`docs/inventory-and-tracing.md`](docs/inventory-and-tracing.md) — inventory and workload instrumentation boundaries.
- [`docs/limitations.md`](docs/limitations.md) — current limitations.
- [`docs/cost-estimate-eu-west-1.md`](docs/cost-estimate-eu-west-1.md) — illustrative cost planning (verify current pricing).

## Validation and cost

Examples are starting points, not production-ready settings. Confirm Terraform/provider versions, AWS permissions, service and Region support, CloudWatch metric dimensions, log retention, collector configuration, and alert routing. Run `terraform init`, `terraform validate`, and `terraform plan` from the chosen example directory. Applying can create billable resources, including alarms, log groups, compute, and telemetry ingestion/storage.
