# AWS observability Terraform module

Terraform modules for inventory-driven CloudWatch alarms and OAM cross-account sharing. Service-specific alarm files live under `modules/observability/services/<service>/`.

> **Scope and safety:** AWS has hundreds of resource types. Terraform cannot enumerate every active resource in an account by itself, and this repository does not claim universal AWS-resource coverage. This module supports the service types listed below when supplied with inventory. Feed it resource IDs and metric dimensions from AWS Config, Resource Explorer, or your own inventory pipeline. It creates only the alarm resources explicitly declared in that inventory; it does not turn off existing alarms or service monitoring settings.

## Supported service folders

`ec2`, `rds`, `ecs`, `lambda`, `emr`, `sagemaker`, `bedrock`, and `agentcore`.

Each service inventory entry contains its CloudWatch metric dimensions and alarm specifications. This keeps metric availability and thresholds explicit and lets teams add service-specific alerts as separate `.tf` files. CloudWatch metrics are not uniform: some are emitted only after workload traffic, some require enhanced monitoring or instrumentation, and AgentCore traces/logs require the appropriate source-side setup.

## Basic usage

The inventory can be generated outside Terraform (for example, from AWS Config) and supplied as a `.tfvars` file. Use stable resource keys and alarm names.

```hcl
module "observability" {
  source = "./modules/observability"

  enabled = true
  scope   = "selected" # "all" means all supported services below, not every AWS service
  services = ["lambda", "rds", "bedrock"]

  resource_inventory = {
    lambda = {
      orders = {
        dimensions = { FunctionName = "orders" }
        alarms = [{
          name                = "orders-errors"
          namespace           = "AWS/Lambda"
          metric_name         = "Errors"
          statistic           = "Sum"
          period              = 300
          evaluation_periods  = 1
          threshold           = 1
          comparison_operator = "GreaterThanOrEqualToThreshold"
          treat_missing_data  = "notBreaching"
        }]
      }
    }
    rds = {
      warehouse = {
        dimensions = { DBInstanceIdentifier = "warehouse" }
        alarms = [{
          name                = "warehouse-cpu"
          namespace           = "AWS/RDS"
          metric_name         = "CPUUtilization"
          statistic           = "Average"
          period              = 300
          evaluation_periods  = 3
          threshold           = 80
          comparison_operator = "GreaterThanThreshold"
          treat_missing_data  = "missing"
        }]
      }
    }
    bedrock = {
      account_inference_errors = {
        dimensions = {}
        alarms = [{
          name                = "bedrock-server-errors"
          namespace           = "AWS/Bedrock"
          metric_name         = "InvocationServerErrors"
          statistic           = "Sum"
          period              = 300
          evaluation_periods  = 1
          threshold           = 1
          comparison_operator = "GreaterThanOrEqualToThreshold"
          treat_missing_data  = "notBreaching"
        }]
      }
    }
  }

  alarm_actions = ["arn:aws:sns:us-east-1:123456789012:platform-alerts"]
  tags = { Environment = "prod", ManagedBy = "terraform" }
}
```

Alarm metric namespaces, dimensions, and thresholds must match the selected AWS service's published metrics in that region. For Bedrock, use documented `AWS/Bedrock` metrics and dimensions; model-level dimensions should only be included when the metric publishes them. SageMaker Studio resources do not all publish the same metric dimensions. AgentCore commonly relies on CloudWatch logs and OpenTelemetry traces as well as metrics; add alarms only for metrics actually emitted in your setup.

## OAM cross-account sharing

Create a sink in the monitoring account using `modules/oam/sink`, then create a link in each source account using `modules/oam/link`. OAM shares CloudWatch telemetry; it does not discover resources, install agents, enable optional service metrics, or configure an OTLP receiver.

```hcl
# Monitoring account
module "oam_sink" {
  source = "./modules/oam/sink"
  name   = "central-observability"
  allowed_account_ids = ["111122223333"]
  resource_types = ["AWS::CloudWatch::Metric", "AWS::Logs::LogGroup"]
}

# Source account (pass the sink ARN from the monitoring account)
module "oam_link" {
  source          = "./modules/oam/link"
  sink_identifier = "arn:aws:oam:us-east-1:444455556666:sink/example"
  label           = "data-platform-prod"
  resource_types  = ["AWS::CloudWatch::Metric", "AWS::Logs::LogGroup"]
}
```

For AWS Organizations, the sink policy can authorize an organization instead of enumerating account IDs. Apply the sink policy and link from credentials/providers in the correct accounts. Configure the OTel gateway and source collectors separately; this repository does not deploy an OTel collector by default.

## Deploy and validate

```sh
terraform -chdir=examples/selected-services init
terraform -chdir=examples/selected-services validate
terraform -chdir=examples/selected-services plan
terraform -chdir=examples/selected-services apply
```

Review plans carefully: removing an inventory resource or alarm specification removes Terraform-managed alarms. Existing alarms not managed by this module are left untouched. Advanced monitoring/instrumentation can incur AWS charges and may require source-account permissions and configuration.
