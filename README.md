# aws-observabilty-module

Terraform modules for building an AWS observability and monitoring foundation across workload and monitoring accounts.

This repository provides reusable Terraform patterns for inventory-driven monitoring, cross-account alarm pipelines, OTel/ADOT deployment patterns, and explicit tracing controls for supported AWS resources.

## What this repository includes

- `modules/observability/` — inventory-based alarm generation and service-level monitoring
- `modules/otel-gateway/` — OTel collector deployment pattern for ADOT ingestion and export
- `modules/tracing/` — explicit tracing controls for native AWS X-Ray and workload OTel/ADOT export
- `examples/monitoring-account/` — monitoring-account deployment patterns
- `examples/selected-services/` — examples for selected service monitoring
- `examples/tracing/` — tracing module usage examples
- `docs/` — implementation guidance, limitations, and design notes

## Observability model

This repository separates three concerns that are often conflated:

1. Inventory and discovery
   - Maps AWS resources and metadata into monitoring configuration
   - Usually created from AWS Config, discovery scripts, or curated inventory input

2. Alarm and monitoring definition
   - Produces CloudWatch alarms, SNS topics, dashboards, and event-driven actions
   - Typically applied in a monitoring account

3. Tracing and telemetry export
   - Native AWS tracing is resource-specific and must be enabled on supported services
   - Application instrumentation (OTel/ADOT) is separate and depends on app code or the runtime integration path

## Tracing model

The tracing module intentionally separates two independent patterns:

### 1) Native AWS X-Ray tracing

Use this when you want to enable native tracing on supported AWS resources.

- `enable_xray_tracing = true` turns on the controller path
- `xray_tracing_services` defines which supported services are allowed
- `native_xray_resources` contains the explicit resource list to update

Currently supported native controls in this module:

- Lambda functions
- API Gateway REST API stages
- Step Functions state machines

Example:

```hcl
module "tracing" {
  source = "./modules/tracing"

  enable_xray_tracing = true
  xray_tracing_services = {
    lambda          = true
    apigateway_rest = true
    stepfunctions   = true
  }

  native_xray_resources = {
    lambda = {
      orders = "arn:aws:lambda:eu-west-1:111122223333:function:orders"
    }
    apigateway_rest = {
      public_api = {
        rest_api_id = "abc123xyz"
        stage_name  = "prod"
        region      = "eu-west-1"
      }
    }
    stepfunctions = {
      ingest = "arn:aws:states:eu-west-1:111122223333:stateMachine:ingest"
    }
  }
}
```

This controller is intentionally explicit and idempotent:

- It only updates allowlisted resources
- It does not broadly enable tracing across every AWS resource
- It does not disable tracing when the setting is turned off

### 2) OTel / ADOT export path

Use this when you want to configure workload-side instrumentation flow rather than a native AWS resource toggle.

- `enable_otel_export = true` activates the workload export gate
- `otel_export_services` lists the workloads or service families to be wired for OTel export
- The module outputs the selected service keys for workload Terraform or deployment code to consume

Example:

```hcl
module "tracing" {
  source = "./modules/tracing"

  enable_otel_export = true
  otel_export_services = {
    ecs       = true
    lambda    = true
    sagemaker = false
  }
}
```

This is not a native AWS resource switch. It is a configuration gate for app-side instrumentation, such as:

- AWS Distro for OpenTelemetry (ADOT) SDK integration
- OTLP exporter configuration
- ECS/EKS/EC2 application instrumentation
- Lambda runtime-specific tracing layers or SDK setup

## Important boundaries

- Native AWS tracing and application instrumentation are separate features.
- Not every AWS service exposes a universal tracing toggle.
- Cross-account monitoring is typically set up in the monitoring account, while workload tracing remains in the workload account.
- Use explicit allowlists and resource definitions to avoid accidental drift, broad permission scopes, and unexpected changes.

## Intended use

This project is designed to help teams standardize:

- inventory-driven CloudWatch monitoring
- cross-account alarm patterns
- collector and gateway setup for telemetry export
- explicit, auditable tracing controls for supported AWS resources
- safe separation between monitoring configuration and application-level observability

## Quick start

1. Review the module examples in `examples/tracing/`.
2. Decide whether your workload needs native X-Ray enablement or ADOT/OTel instrumentation.
3. Populate the explicit resource list for the relevant AWS services.
4. Keep OAM, CloudWatch alarms, and application instrumentation as separate deployment concerns.

## Notes

- AWS service tracing capabilities differ by resource type and region.
- Application tracing requires compatible SDKs, collectors, or Lambda layers
- Validate IAM least-privilege permissions and regional prerequisites before production rollout
