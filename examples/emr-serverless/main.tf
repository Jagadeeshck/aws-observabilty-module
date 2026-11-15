locals {
  selected_services = ["emr_serverless"]

  emr_serverless_inventory = {
    spark_driver_job = {
      dimensions = {
        ApplicationId = "00fexampleapp"
        JobId         = "00fexamplejob"
        WorkerType    = "Spark-Driver"
      }
      alarms = [{
        name                = "spark-driver-cpu-used"
        namespace           = "AWS/EMRServerless"
        metric_name         = "WorkerCpuUsed"
        statistic           = "Maximum"
        period              = 300
        evaluation_periods  = 3
        threshold           = 4
        comparison_operator = "GreaterThanThreshold"
        treat_missing_data  = "notBreaching"
      }]
    }
  }
}

module "observability" {
  source = "../../modules/observability"

  enabled       = true
  enable_alerts = true
  scope         = "selected"
  services      = local.selected_services
  resource_inventory = {
    emr_serverless = local.emr_serverless_inventory
  }
}
