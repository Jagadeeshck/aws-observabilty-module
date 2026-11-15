locals {
  supported_services = ["ec2", "rds", "ecs", "lambda", "emr", "sagemaker", "bedrock", "agentcore"]
  selected_services  = var.enabled ? (var.scope == "all" ? local.supported_services : sort(tolist(var.services))) : []
  inventory          = { for service in local.supported_services : service => try(var.resource_inventory[service], {}) }
  common_tags        = merge({ ManagedBy = "terraform", Module = "aws-observability" }, var.tags)
}
