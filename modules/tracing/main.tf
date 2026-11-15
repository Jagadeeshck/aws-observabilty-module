locals {
  native_lambda_resources = [
    for key, arn in var.native_xray_resources.lambda : {
      key = key, service = "lambda", resource_arn = arn
    } if lookup(var.xray_tracing_services, "lambda", false)
  ]
  native_sfn_resources = [
    for key, arn in var.native_xray_resources.stepfunctions : {
      key = key, service = "stepfunctions", resource_arn = arn
    } if lookup(var.xray_tracing_services, "stepfunctions", false)
  ]
  native_apigw_resources = [
    for key, item in var.native_xray_resources.apigateway_rest : {
      key = key, service = "apigateway_rest", rest_api_id = item.rest_api_id, stage_name = item.stage_name, region = item.region
    } if lookup(var.xray_tracing_services, "apigateway_rest", false)
  ]
  native_config = var.enable_xray_tracing ? concat(local.native_lambda_resources, local.native_sfn_resources, local.native_apigw_resources) : []

  lambda_arns = [for resource in local.native_lambda_resources : resource.resource_arn]
  state_machine_arns = [for resource in local.native_sfn_resources : resource.resource_arn]
  apigateway_stage_arns = [for resource in local.native_apigw_resources : "arn:aws:apigateway:${resource.region}::/restapis/${resource.rest_api_id}/stages/${resource.stage_name}"]
  policy_statements = concat(
    length(local.lambda_arns) > 0 ? [{ Effect = "Allow", Action = ["lambda:GetFunctionConfiguration", "lambda:UpdateFunctionConfiguration"], Resource = local.lambda_arns }] : [],
    length(local.state_machine_arns) > 0 ? [{ Effect = "Allow", Action = ["states:DescribeStateMachine", "states:UpdateStateMachine"], Resource = local.state_machine_arns }] : [],
    length(local.apigateway_stage_arns) > 0 ? [{ Effect = "Allow", Action = ["apigateway:GET", "apigateway:PATCH"], Resource = local.apigateway_stage_arns }] : []
  )
  otel_export_enabled_services = var.enable_otel_export ? sort([for service, enabled in var.otel_export_services : service if enabled]) : []
}

data "archive_file" "controller" {
  type        = "zip"
  source_file = "${path.module}/lambda_src/handler.py"
  output_path = "${path.module}/xray_controller.zip"
}

resource "aws_cloudwatch_log_group" "controller" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = 30
  tags              = var.tags
}

resource "aws_iam_role" "controller" {
  name = "${var.name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "controller" {
  name = "${var.name}-policy"
  role = aws_iam_role.controller.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      { Effect = "Allow", Action = ["logs:CreateLogStream", "logs:PutLogEvents"], Resource = "${aws_cloudwatch_log_group.controller.arn}:*" }
    ], local.policy_statements)
  })
}

resource "aws_lambda_function" "controller" {
  function_name    = var.name
  role             = aws_iam_role.controller.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.controller.output_path
  source_code_hash = data.archive_file.controller.output_base64sha256
  timeout          = 60
  memory_size      = 256
  environment {
    variables = {
      ENABLE_XRAY_TRACING = tostring(var.enable_xray_tracing)
      NATIVE_RESOURCES    = jsonencode(local.native_config)
    }
  }
  depends_on = [aws_iam_role_policy.controller]
  tags       = var.tags
}

resource "aws_cloudwatch_event_rule" "controller" {
  name                = "${var.name}-schedule"
  schedule_expression = var.schedule_expression
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "controller" {
  rule = aws_cloudwatch_event_rule.controller.name
  arn  = aws_lambda_function.controller.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowScheduledXrayReconciliation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.controller.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.controller.arn
}
