# This module intentionally supplies infrastructure scaffolding only. Collector config delivery and persistent config storage must be completed for your deployment before enabling the ECS service.
resource "aws_ecs_service" "collector" {
  count           = var.enabled ? 1 : 0
  name            = var.name
  cluster         = aws_ecs_cluster.this[0].id
  task_definition  = aws_ecs_task_definition.collector[0].arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.gateway[0].id]
    assign_public_ip = false
  }
  tags = var.tags
}
