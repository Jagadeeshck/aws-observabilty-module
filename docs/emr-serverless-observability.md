# Amazon EMR Serverless and Spark observability

EMR Serverless monitoring has three complementary layers. The observability module creates CloudWatch alarms from the `emr_serverless` inventory; it does not instrument Spark applications or create EventBridge rules/log destinations automatically.

## CloudWatch metrics and alarms

EMR Serverless publishes resource metrics in the `AWS/EMRServerless` namespace. AWS documents application metrics and job/worker metrics separately. Use the exact metric dimensions published for the metric and Region; job/worker metrics generally require the application and job identifiers and may include `WorkerType` and `CapacityAllocationType`. Do not assume every metric is available at application-only granularity.

Example inventory for a known Spark job run:

```hcl
resource_inventory = {
  emr_serverless = {
    spark_driver = {
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
```

The threshold is an example resource quantity, not a percent. Tune it to the metric's documented unit and your application's expected capacity. Job run IDs are ephemeral; for longer-lived application monitoring, configure application-level metrics and their documented dimensions rather than pinning alarms to a single run. Add custom alarms for memory, storage, allocation, or I/O metrics only after confirming the metric name, unit, dimensions, and statistic in the AWS documentation and CloudWatch console.

Select the service in the top-level module with `services = ["emr_serverless"]` and enable alarm creation with `enable_alerts = true`. `scope = "all"` also selects it.

## Job lifecycle notifications

Use EventBridge EMR Serverless job run state-change events for `SUBMITTED`, `PENDING`, `SCHEDULED`, `RUNNING`, `SUCCESS`, `FAILED`, and `CANCELLED` lifecycle notifications as applicable. These are events, not metrics such as `FailedJobRunCount`; use an EventBridge rule and an appropriate target (for example, SNS, SQS, Lambda, or an incident integration) to alert on failed jobs. EventBridge rules and targets are separate from the CloudWatch alarm module.

## Logs and Spark diagnostics

Configure EMR Serverless application/job logging to CloudWatch Logs and/or S3 according to retention and access requirements. Spark event logs support Spark UI/history diagnostics; CloudWatch metric alarms do not replace driver/executor logs or stage/task-level analysis.

## References

- [Monitoring EMR Serverless applications and jobs](https://docs.aws.amazon.com/emr/latest/EMR-Serverless-UserGuide/app-job-metrics.html)
- [EMR Serverless CloudWatch metrics reference](https://docs.aws.amazon.com/emr/latest/EMR-Serverless-UserGuide/monitoring-cloudwatch-metrics-reference.html)
- [Logging for EMR Serverless](https://docs.aws.amazon.com/emr/latest/EMR-Serverless-UserGuide/logging.html)
- [EMR Serverless EventBridge events](https://docs.aws.amazon.com/emr/latest/EMR-Serverless-UserGuide/application-eventbridge.html)
- [View the Spark UI for EMR Serverless](https://docs.aws.amazon.com/emr/latest/EMR-Serverless-UserGuide/spark-ui-view.html)
