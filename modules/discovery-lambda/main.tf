locals {
  source_dir = "${path.module}/lambda_src"
  artifact_path = "${path.module}/lambda_package.zip"
}

resource "aws_iam_role" "this" {
  count = var.enabled ? 1 : 0
  name  = "${var.name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
  tags = var.tags
}

resource "aws_iam_policy" "this" {
  count = var.enabled ? 1 : 0
  name  = "${var.name}-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Sid    = "ReadInventory"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceAttribute",
          "ec2:MonitorInstances",
          "lambda:ListFunctions",
          "lambda:GetFunction",
          "lambda:UpdateFunctionConfiguration",
          "rds:DescribeDBInstances",
          "rds:ModifyDBInstance",
          "ecs:ListClusters",
          "ecs:DescribeClusters",
          "logs:DescribeLogGroups",
          "sns:Publish",
          "s3:GetBucketLogging",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "config:ListDiscoveredResources",
          "config:Describe*",
          "config:Get*",
          "dynamodb:DescribeTable",
          "dynamodb:ListTables",
          "es:ListDomainNames",
          "es:DescribeElasticsearchDomain",
          "athena:ListWorkGroups",
          "glue:GetJobs",
          "glue:GetCrawler",
          "route53:ListHostedZones",
          "route53:GetHealthCheck",
          "sagemaker:ListEndpoints",
          "sagemaker:DescribeEndpoint",
          "sagemaker:ListNotebookInstances",
          "sagemaker:DescribeNotebookInstance",
          "bedrock:ListAgents",
          "bedrock:ListGuardrails",
          "bedrock:ListKnowledgeBases",
          "bedrock:ListInferenceProfiles",
          "bedrock:ListCustomModels",
          "resource-groups:ListGroups"
        ],
        Resource = "*"
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  count      = var.enabled ? 1 : 0
  role       = aws_iam_role.this[0].name
  policy_arn = aws_iam_policy.this[0].arn
}

resource "aws_cloudwatch_log_group" "this" {
  count = var.enabled ? 1 : 0
  name  = "/aws/lambda/${var.name}"
  retention_in_days = 30
  tags = var.tags
}

data "archive_file" "lambda" {
  count       = var.enabled ? 1 : 0
  type        = "zip"
  source_dir  = local.source_dir
  output_path = local.artifact_path
}

resource "aws_lambda_function" "this" {
  count = var.enabled ? 1 : 0
  function_name = var.name
  role          = aws_iam_role.this[0].arn
  handler       = "lambda_function.lambda_handler"
  runtime       = var.lambda_runtime
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout
  filename      = data.archive_file.lambda[0].output_path
  source_code_hash = data.archive_file.lambda[0].output_base64sha256
  environment {
    variables = {
      REPORT_BUCKET_NAME        = var.report_bucket_name == null ? "" : var.report_bucket_name
      REPORT_S3_PREFIX          = var.report_s3_prefix
      REPORT_TOPIC_ARN          = var.report_topic_arn == null ? "" : var.report_topic_arn
      SERVICES                  = join(",", var.services)
      ENABLE_OBSERVABILITY      = tostring(var.enable_observability)
      OBSERVABILITY_SETTINGS    = jsonencode(var.observability_service_settings)
      REGION_NAME               = data.aws_region.current.name
    }
  }
  tags = var.tags
}

data "aws_region" "current" {}

resource "aws_cloudwatch_event_rule" "this" {
  count               = var.enabled ? 1 : 0
  name                = "${var.name}-schedule"
  schedule_expression = var.schedule_expression
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "this" {
  count = var.enabled ? 1 : 0
  rule  = aws_cloudwatch_event_rule.this[0].name
  arn   = aws_lambda_function.this[0].arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  count         = var.enabled ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this[0].arn
}

output "lambda_arn" {
  value       = var.enabled ? aws_lambda_function.this[0].arn : null
  description = "Discovery Lambda ARN."
}

output "lambda_name" {
  value       = var.enabled ? aws_lambda_function.this[0].function_name : null
  description = "Discovery Lambda name."
}
