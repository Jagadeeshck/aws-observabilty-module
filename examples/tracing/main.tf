module "tracing" {
  source = "../../modules/tracing"

  enable_xray_tracing = true
  xray_tracing_services = {
    lambda          = true
    apigateway_rest = true
    stepfunctions   = true
  }
  native_xray_resources = {
    lambda = { example_fn = "arn:aws:lambda:eu-west-1:111122223333:function:example-fn" }
    apigateway_rest = {
      example_api = { rest_api_id = "abc123xyz", stage_name = "prod", region = "eu-west-1" }
    }
    stepfunctions = { example_workflow = "arn:aws:states:eu-west-1:111122223333:stateMachine:example" }
  }
  target_role_arns = {
    lambda = { example_fn = "arn:aws:iam::111122223333:role/example-function-execution" }
    stepfunctions = { example_workflow = "arn:aws:iam::111122223333:role/example-state-machine" }
  }

  enable_otel_export = true
  otel_export_services = {
    ecs       = true
    lambda    = true
    sagemaker = false
  }
}

output "otel_services_to_instrument" {
  value = module.tracing.otel_export_enabled_services
}
