data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_group" "collector" {
  name              = "/aws/otel/${var.name}"
  retention_in_days = 30
  tags              = var.tags
}

resource "aws_ecs_cluster" "this" {
  count = var.enabled ? 1 : 0
  name  = var.name
  tags  = var.tags
}

resource "aws_iam_role" "task_execution" {
  count = var.enabled ? 1 : 0
  name  = "${var.name}-execution"
  assume_role_policy = jsonencode({Version="2012-10-17",Statement=[{Effect="Allow",Principal={Service="ecs-tasks.amazonaws.com"},Action="sts:AssumeRole"}]})
  tags = var.tags
}
resource "aws_iam_role_policy_attachment" "execution" {
  count      = var.enabled ? 1 : 0
  role       = aws_iam_role.task_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_role" "task" {
  count = var.enabled ? 1 : 0
  name  = "${var.name}-task"
  assume_role_policy = jsonencode({Version="2012-10-17",Statement=[{Effect="Allow",Principal={Service="ecs-tasks.amazonaws.com"},Action="sts:AssumeRole"}]})
  tags = var.tags
}
resource "aws_iam_role_policy" "xray" {
  count = var.enabled ? 1 : 0
  name  = "${var.name}-xray-write"
  role  = aws_iam_role.task[0].id
  policy = jsonencode({Version="2012-10-17",Statement=[{Effect="Allow",Action=["xray:PutTraceSegments","xray:PutTelemetryRecords"],Resource="*"}]})
}
resource "aws_security_group" "gateway" {
  count       = var.enabled ? 1 : 0
  name        = "${var.name}-ingress"
  description = "Restricted OTLP ingress for ADOT gateway"
  vpc_id      = var.vpc_id
  ingress { from_port = var.listener_port; to_port = var.listener_port; protocol = "tcp"; cidr_blocks = var.allowed_cidr_blocks }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
  tags = var.tags
}
resource "aws_ecs_task_definition" "collector" {
  count                    = var.enabled ? 1 : 0
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.task_execution[0].arn
  task_role_arn            = aws_iam_role.task[0].arn
  container_definitions = jsonencode([{
    name="adot-collector", image=var.image, essential=true,
    command=["--config=/etc/ecs/otel-config.yaml"],
    portMappings=[{containerPort=var.listener_port,protocol="tcp"}],
    mountPoints=[{sourceVolume="collector-config",containerPath="/etc/ecs",readOnly=true}],
    logConfiguration={logDriver="awslogs",options={"awslogs-group"=aws_cloudwatch_log_group.collector.name,"awslogs-region"=data.aws_region.current.name,"awslogs-stream-prefix"="collector"}}
  }])
  volume { name = "collector-config"; efs_volume_configuration { file_system_id = "replace-with-managed-config-volume"; root_directory = "/" } }
  tags = var.tags
}
