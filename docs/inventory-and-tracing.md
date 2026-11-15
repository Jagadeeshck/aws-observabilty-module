# Inventory and tracing examples

`discover_inventory.py` queries resource records already present in an AWS Config aggregator. It does not activate Config recorders or cover resource types that Config does not record. Grant least-privilege Config query permissions; run once per inventory refresh and review the generated file before applying.

```sh
python -m pip install -r scripts/requirements.txt
python scripts/discover_inventory.py \
  --aggregator-name org-inventory \
  --regions us-east-1,us-west-2 \
  --services ec2,rds,lambda,dynamodb,s3,athena,glue,datazone,opensearch,route53,iam \
  --output examples/selected-services/inventory.auto.tfvars.json
```

The script generates baseline alarm specs only for resource/metric pairs with known dimensions in its mapping. Other discovered resources are included with empty alarm lists and must be given service-specific alarm specifications after validating CloudWatch metric namespaces/dimensions. In particular IAM is event/security monitoring (CloudTrail/EventBridge), not a universal CloudWatch metric namespace; Route 53 health-check metrics and S3 request metrics may require configuration such as health checks or request metrics. S3 Tables and AgentCore resource discovery may be absent from AWS Config's supported recording types and require another inventory feed.

## ADOT traces

ADOT cannot be attached generically to every AWS resource. Traces require instrumented application code or a supported integration plus a configured exporter/collector. Use OAM for shared CloudWatch metrics/logs; use OTLP from source workloads to a secured ADOT gateway (or an AWS-supported trace destination) for application traces. Do not expose OTLP endpoints publicly.

For Lambda, the function-owning Terraform must add the runtime-appropriate ADOT layer ARN and execution-wrapper environment settings to the existing `aws_lambda_function`; a monitoring-account module cannot safely mutate an unrelated function resource. Obtain the official layer ARN/version for the function region and runtime from AWS's ADOT Lambda documentation and add it as a layer in the function's existing `layers` list. Preserve existing layers and environment variables.

For ECS/EKS/EC2, deploy a collector and instrument applications with OpenTelemetry SDK/auto-instrumentation. Configure network access with TLS/authentication and least privilege. The `modules/otel-gateway` directory is a starting point, not a turnkey production gateway: complete collector configuration delivery, TLS/auth, health checks, capacity scaling, and tracing backend/exporter settings before deployment. Review IAM actions and network rules. Avoid exporting secrets or sensitive span attributes.
