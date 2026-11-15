# Native X-Ray and OTel/ADOT tracing controls

This module exposes two separate tracing paths. Use it in the **workload account** because it changes native resource settings.

## Native AWS X-Ray

`enable_xray_tracing` is the master switch. `xray_tracing_services` is the per-service allowlist, and `native_xray_resources` explicitly lists the resources. A scheduled, idempotent Lambda enables tracing for:

- Lambda functions (`TracingConfig.Mode = Active`)
- API Gateway REST API stages (`tracingEnabled = true`)
- Step Functions state machines (`tracingConfiguration.enabled = true`)

Example:

```hcl
module "tracing" {
  source = "../../modules/tracing"

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
      ingest_workflow = "arn:aws:states:eu-west-1:111122223333:stateMachine:ingest"
    }
  }
  target_role_arns = {
    lambda = {
      orders = "arn:aws:iam::111122223333:role/orders-execution"
    }
    stepfunctions = {
      ingest_workflow = "arn:aws:iam::111122223333:role/ingest-state-machine"
    }
  }
}
```

The module attaches `xray:PutTraceSegments` and `xray:PutTelemetryRecords` to the explicitly supplied Lambda execution roles and Step Functions service roles. API Gateway REST tracing also requires the API Gateway account-level CloudWatch role to be configured for X-Ray in that region.

The controller **only enables** tracing and never turns it off. It processes only the explicit allowlist. It does not update Terraform state for those resources; if the same resources are declared in another Terraform stack, reconcile their tracing settings there too to avoid drift. It logs per-resource failures and fails the invocation after processing all entries so asynchronous retries and CloudWatch Lambda error alarms can detect failures. Allowlist payloads are capped at 3000 serialized bytes to leave room below Lambda's 4 KB aggregate environment-variable limit; split larger inventories across module instances.

The role policies managed by this module are Terraform-managed and will be removed if the corresponding allowlist entry is removed. Review every plan and ensure these policy attachments do not conflict with policies managed by another stack.

## OTel/ADOT export

Use `enable_otel_export` and `otel_export_services` as explicit per-workload gates. The module outputs the selected service keys for workload Terraform to consume:

```hcl
module "tracing" {
  source = "../../modules/tracing"
  enable_xray_tracing = false
  enable_otel_export = true
  otel_export_services = {
    ecs       = true
    lambda    = true
    sagemaker = false
  }
}

output "services_to_configure_for_otel" {
  value = module.tracing.otel_export_enabled_services
}
```

This gate does not inject SDKs/layers, mutate task definitions, or create spans. Application code must be instrumented and configured to export OTLP to a private, authenticated ADOT Collector. For Lambda, use the runtime-appropriate ADOT layer/wrapper or SDK from the function-owning deployment. For ECS/EC2/SageMaker, instrument the application and configure the collector/exporter. AWS-managed services without a supported instrumentation/API remain unsupported by generic tracing toggles.

Keep OAM and alarm configuration separate: OAM shares eligible CloudWatch telemetry, and monitoring-account alarms query source metrics. X-Ray tracing is configured in the workload account; configure X-Ray access and destinations according to your cross-account architecture.
