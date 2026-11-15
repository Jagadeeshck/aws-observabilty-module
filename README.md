# aws-observabilty-module

Terraform modules for building an AWS observability and monitoring foundation across workload and monitoring accounts.

This repository is organized around reusable modules for:

- observability alarm generation from service inventory
- OTel/ADOT gateway and collector patterns
- cross-account monitoring and alerting patterns
- native AWS X-Ray tracing enablement for explicitly selected resources
- OTel export gating for instrumented workloads

## Repository layout

- `modules/observability/` — inventory-driven observability alarm module
- `modules/otel-gateway/` — OTel collector gateway for ADOT ingress/export patterns
- `modules/tracing/` — separate native X-Ray and OTel control layer
- `examples/monitoring-account/` — monitoring account example configuration
- `examples/selected-services/` — example module usage for a subset of services
- `examples/tracing/` — tracing module examples
- `docs/` — design and limitations notes

## Tracing model

The tracing implementation intentionally separates two patterns:

1. Native AWS tracing controls
   - `enable_xray_tracing = true`
   - `xray_tracing_services` defines the supported services
   - `native_xray_resources` explicitly lists resources to update
   - Supported resources in this module today: Lambda, API Gateway REST stages, and Step Functions

2. OTel/ADOT workload instrumentation flow
   - `enable_otel_export = true`
   - `otel_export_services` defines the service keys to be consumed by workload Terraform
   - This does not automatically enable tracing for AWS-managed resources
   - Your application or ECS/EKS/Lambda deployment still needs SDK or ADOT layer configuration

## Example: native X-Ray tracing

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

## Example: OTel export gate

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

This exposes the selected service names for workload deployment configuration without pretending that all AWS resources support a universal tracing toggle.

## Notes

- AWS-managed tracing toggles are resource-specific and not universal.
- OTel/ADOT instrumentation still requires app-level configuration and collector wiring.
- Cross-account monitoring patterns should keep alarm generation in the monitoring account and tracing configuration in the workload account.
- Use explicit allowlists instead of broad, implicit tracing changes to reduce accidental drift and cost.
