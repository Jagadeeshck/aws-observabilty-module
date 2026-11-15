# AWS observability Terraform module

Inventory-driven CloudWatch alarms for a monitoring account, OAM cross-account sharing, and ADOT integration guidance. Service-specific configuration lives under `modules/observability/services/<service>/`; monitoring-account examples use standalone `alert_<service>.tf` files.

## Alert behavior

Set `enable_alerts = true` to create the module's baseline alarms plus custom alarms supplied in `resource_inventory`. Set it to `false` to create no alarms. `enabled` remains a master module switch. `scope = "all"` means all service types supported by this module; `scope = "selected"` uses `services`.

Alarms are created in the account where the observability module is applied. For cross-account alarms, apply the alarm module using monitoring-account credentials and provide each inventory resource's source `account_id` and `region`. The metric query then reads that source account's metric through configured CloudWatch cross-account observability/OAM. Alarm actions (for example SNS) should be resources/ARNs in the monitoring account.

> Terraform does not discover every AWS resource automatically. The included discovery script reads resources recorded in an AWS Config aggregator. Config coverage and freshness vary; review the generated inventory and plan. This module only monitors inventory entries and metrics explicitly supported/configured.

## Service coverage

Folders are provided for EC2, RDS, ECS, Lambda, EMR, SageMaker, Bedrock, AgentCore, S3, S3 Tables, Athena, Glue, DataZone, DynamoDB, OpenSearch, IAM, and Route 53. Baseline alarms are configured only where a stable native CloudWatch metric and resource dimension are known. Other services accept custom alarms but intentionally do not invent non-existent metrics. S3 request metrics, some SageMaker metrics, and AgentCore telemetry may need source-side configuration/instrumentation.

## Example: monitoring account

```hcl
module "observability" {
  source = "../../modules/observability"

  enabled       = true
  enable_alerts = true
  scope         = "selected"
  services      = ["ec2", "rds", "lambda", "s3", "bedrock"]

  # Inventory comes from AWS Config or another discovery pipeline. Each entry
  # is keyed stably and includes source-account metric dimensions.
  resource_inventory = var.resource_inventory
  alarm_actions      = [aws_sns_topic.alerts.arn]
  tags               = { Environment = "prod", ManagedBy = "terraform" }
}
```

A cross-account inventory item looks like:

```hcl
resource_inventory = {
  ec2 = {
    prod_instance = {
      account_id = "111122223333"
      region     = "us-east-1"
      dimensions = { InstanceId = "i-0123456789abcdef0" }
      alarms = [] # optional custom alerts, added to defaults
    }
  }
}
```

See `examples/monitoring-account/alerts/alert_ec2.tf` and sibling files for explicit, standalone alarm definitions and custom alert examples. The module's built-in defaults are generated from `locals.tf`; custom alarms can be added per inventory resource without replacing the defaults.

## OAM

Use `modules/oam/sink` in the monitoring account and `modules/oam/link` in each source account. OAM shares eligible CloudWatch metrics/logs; it does not create alarms, discover resources, enable optional service metrics, or transport OTLP traces. The monitoring account must have the appropriate OAM sink/link setup and IAM permissions.

## Discovery and traces

See `docs/inventory-and-tracing.md` for AWS Config inventory generation, limitations, and ADOT setup guidance. ADOT traces require workload instrumentation or a supported integration plus an exporter/collector. They cannot be generically attached to arbitrary AWS resources. Lambda function-owning code can add the appropriate ADOT layer while preserving existing layers and environment variables; ECS/EKS/EC2 workloads need an instrumented app and a secured collector endpoint.

## Validate

```sh
python -m pip install -r scripts/requirements.txt
python scripts/discover_inventory.py --aggregator-name org-inventory --regions us-east-1 --services ec2,rds,lambda --output examples/monitoring-account/inventory.auto.tfvars.json
terraform -chdir=examples/monitoring-account init
terraform -chdir=examples/monitoring-account validate
terraform -chdir=examples/monitoring-account plan
```

Review every plan before applying. Removing an inventory entry or alarm specification can destroy Terraform-managed alarms; unrelated alarms are not imported, modified, or disabled. Enhanced metrics and instrumentation can incur AWS charges.
