locals {
  supported_services = ["ec2", "rds", "ecs", "lambda", "emr", "sagemaker", "bedrock", "agentcore", "s3", "s3_tables", "athena", "glue", "datazone", "dynamodb", "opensearch", "iam", "route53"]
  selected_services  = var.enabled ? (var.scope == "all" ? local.supported_services : sort(tolist(var.services))) : []
  alerts_enabled     = var.enabled && var.enable_alerts

  # Safe defaults only for documented, resource-dimensioned native metrics.
  # Resources/services without a universal metric accept custom alarm specs.
  default_alarm_templates = {
    ec2 = [{ suffix="status-check-failed", namespace="AWS/EC2", metric_name="StatusCheckFailed", statistic="Maximum", period=300, evaluation_periods=2, threshold=0, comparison_operator="GreaterThanThreshold", treat_missing_data="notBreaching" }]
    rds = [{ suffix="cpu-high", namespace="AWS/RDS", metric_name="CPUUtilization", statistic="Average", period=300, evaluation_periods=3, threshold=80, comparison_operator="GreaterThanThreshold", treat_missing_data="missing" }]
    lambda = [{ suffix="errors", namespace="AWS/Lambda", metric_name="Errors", statistic="Sum", period=300, evaluation_periods=1, threshold=1, comparison_operator="GreaterThanOrEqualToThreshold", treat_missing_data="notBreaching" }]
    dynamodb = [{ suffix="system-errors", namespace="AWS/DynamoDB", metric_name="SystemErrors", statistic="Sum", period=300, evaluation_periods=1, threshold=1, comparison_operator="GreaterThanOrEqualToThreshold", treat_missing_data="notBreaching" }]
    sagemaker = [{ suffix="invocation-5xx", namespace="AWS/SageMaker", metric_name="Invocation5XXErrors", statistic="Sum", period=300, evaluation_periods=1, threshold=1, comparison_operator="GreaterThanOrEqualToThreshold", treat_missing_data="notBreaching" }]
    bedrock = [{ suffix="server-errors", namespace="AWS/Bedrock", metric_name="InvocationServerErrors", statistic="Sum", period=300, evaluation_periods=1, threshold=1, comparison_operator="GreaterThanOrEqualToThreshold", treat_missing_data="notBreaching" }]
    route53 = [{ suffix="health-check-unhealthy", namespace="AWS/Route53", metric_name="HealthCheckStatus", statistic="Minimum", period=60, evaluation_periods=3, threshold=1, comparison_operator="LessThanThreshold", treat_missing_data="breaching" }]
  }

  raw_inventory = { for service in local.supported_services : service => try(var.resource_inventory[service], {}) }
  inventory = {
    for service in local.supported_services : service => {
      for resource_key, resource in local.raw_inventory[service] : resource_key => merge(resource, {
        alarms = concat(
          [for spec in lookup(local.default_alarm_templates, service, []) : {
            name = "${service}-${resource_key}-${spec.suffix}"
            namespace = spec.namespace
            metric_name = spec.metric_name
            statistic = spec.statistic
            period = spec.period
            evaluation_periods = spec.evaluation_periods
            threshold = spec.threshold
            comparison_operator = spec.comparison_operator
            treat_missing_data = spec.treat_missing_data
          }],
          try(resource.alarms, [])
        )
      })
    }
  }
  common_tags = merge({ ManagedBy = "terraform", Module = "aws-observability" }, var.tags)
}
