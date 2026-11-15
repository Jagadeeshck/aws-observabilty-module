provider "aws" {
  region = "us-east-1"
}

module "observability" {
  source = "../../modules/observability"
  enabled = true
  scope = "selected"
  services = ["lambda", "rds", "bedrock", "sagemaker", "agentcore"]
  resource_inventory = var.resource_inventory
  alarm_actions = var.alarm_actions
  ok_actions = var.ok_actions
  tags = var.tags
}
