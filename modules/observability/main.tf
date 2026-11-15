module "ec2" {
  count = contains(local.selected_services, "ec2") ? 1 : 0
  source = "./services/ec2"
  resource_inventory = local.inventory.ec2
  alarm_actions = var.alarm_actions
  ok_actions = var.ok_actions
  tags = local.common_tags
}
module "rds" {
  count = contains(local.selected_services, "rds") ? 1 : 0
  source = "./services/rds"
  resource_inventory = local.inventory.rds
  alarm_actions = var.alarm_actions
  ok_actions = var.ok_actions
  tags = local.common_tags
}
module "ecs" {
  count = contains(local.selected_services, "ecs") ? 1 : 0
  source = "./services/ecs"
  resource_inventory = local.inventory.ecs
  alarm_actions = var.alarm_actions
  ok_actions = var.ok_actions
  tags = local.common_tags
}
module "lambda" {
  count = contains(local.selected_services, "lambda") ? 1 : 0
  source = "./services/lambda"
  resource_inventory = local.inventory.lambda
  alarm_actions = var.alarm_actions
  ok_actions = var.ok_actions
  tags = local.common_tags
}
module "emr" {
  count = contains(local.selected_services, "emr") ? 1 : 0
  source = "./services/emr"
  resource_inventory = local.inventory.emr
  alarm_actions = var.alarm_actions
  ok_actions = var.ok_actions
  tags = local.common_tags
}
module "sagemaker" {
  count = contains(local.selected_services, "sagemaker") ? 1 : 0
  source = "./services/sagemaker"
  resource_inventory = local.inventory.sagemaker
  alarm_actions = var.alarm_actions
  ok_actions = var.ok_actions
  tags = local.common_tags
}
module "bedrock" {
  count = contains(local.selected_services, "bedrock") ? 1 : 0
  source = "./services/bedrock"
  resource_inventory = local.inventory.bedrock
  alarm_actions = var.alarm_actions
  ok_actions = var.ok_actions
  tags = local.common_tags
}
module "agentcore" {
  count = contains(local.selected_services, "agentcore") ? 1 : 0
  source = "./services/agentcore"
  resource_inventory = local.inventory.agentcore
  alarm_actions = var.alarm_actions
  ok_actions = var.ok_actions
  tags = local.common_tags
}
