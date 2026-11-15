# Native X-Ray and OTel/ADOT tracing controls

This module exposes two separate tracing paths. Use it in the **workload account** because it changes native resource settings there.

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
}
```

The controller **only enables** tracing and never turns it off. It processes only the explicit allowlist. It does not update Terraform state for those resources; if the same resources are declared in another Terraform stack, reconcile their tracing settings there too to avoid drift. Review the scheduled function's results and logs after deployment. Update permissions and resource identifiers to your account, and validate API Gateway execution-role/X-Ray prerequisites.

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
