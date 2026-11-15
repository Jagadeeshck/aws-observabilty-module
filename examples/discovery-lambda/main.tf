provider "aws" {
  region = "us-east-1"
}

module "discovery_lambda" {
  source = "../../modules/discovery-lambda"

  enabled = true
  name    = "aws-observability-discovery"
  services = ["ec2", "rds", "lambda", "dynamodb", "s3", "route53"]

  report_bucket_name = "my-discovery-bucket"
  report_s3_prefix   = "aws-observability-discovery/"
  enable_observability = true

  observability_service_settings = {
    lambda = {
      enabled      = true
      tracing_mode = "Active"
    }
    ec2 = {
      enabled             = true
      detailed_monitoring = true
    }
    rds = {
      enabled               = true
      performance_insights  = true
    }
  }

  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
