output "cluster_arn" { value = try(aws_ecs_cluster.this[0].arn, null) }
output "security_group_id" { value = try(aws_security_group.gateway[0].id, null) }
output "collector_log_group" { value = aws_cloudwatch_log_group.collector.name }
