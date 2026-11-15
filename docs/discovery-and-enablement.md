# Discovery Lambda and reporting design

The discovery Lambda runs in the same AWS account as the workload and reports resource inventory plus the current observability posture. It can also optionally enable supported observability settings where that is safe and explicit.

## Why use a Lambda

This gives you a single place to:
- inventory active AWS resources by service
- record whether CloudWatch metrics, logging, tracing, and service-specific settings are enabled
- feed the result to an S3 bucket / SNS topic / log store for the monitoring account
- optionally reconcile supported service settings such as Lambda tracing or EC2 detailed monitoring

## Important boundaries

- The discovery Lambda is not metadata magic: it cannot render every AWS resource type or automatically enable every observability feature.
- It should run with a least-privilege role tied to a limited list of supported services.
- It can opt in to service-specific enablement, but only on services with safe and supported APIs.
- The actual cross-account alarm creation remains in the monitoring account via the `modules/observability` alarm module.
- Tracing is runtime-specific and application-level; it requires application instrumentation or a supported ADOT layer for Lambda, ECS, or EKS.

## Example execution

```bash
aws lambda invoke \
  --function-name aws-observability-discovery \
  --payload '{"action":"report"}' \
  response.json
```

The response payload can be serialized to a JSON report in S3 or published to SNS for monitoring-account consumption.
