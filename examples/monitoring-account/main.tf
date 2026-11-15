locals {
  selected_services = ["ec2", "rds", "lambda", "s3", "s3_tables", "athena", "glue", "datazone", "dynamodb", "opensearch", "iam", "route53", "sagemaker", "bedrock", "agentcore", "ecs", "emr"]
}
module "observability" {
  source = "../../modules/observability"
  enabled = true
  enable_alerts = var.enable_alerts
  scope = "selected"
  services = local.selected_services
  resource_inventory = var.resource_inventory
}
