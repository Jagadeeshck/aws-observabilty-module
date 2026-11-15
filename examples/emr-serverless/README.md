# EMR Serverless and Spark observability example

This opt-in example configures an inventory-driven CloudWatch alarm for a Spark driver worker metric. Replace the placeholder application/job IDs and verify the metric dimensions, unit, and threshold for your account and Region before applying.

The job ID is run-specific, so this sample is most useful for a known or actively tracked job run. For recurring job failure notifications, configure a separate EventBridge rule for EMR Serverless job run state-change events. Configure application/job log delivery to CloudWatch Logs or S3 to support Spark UI/history diagnostics.

Run from this directory after configuring AWS credentials:

```sh
terraform init
terraform validate
terraform plan
```

Review the plan; applying creates billable CloudWatch alarms. See [`../../docs/emr-serverless-observability.md`](../../docs/emr-serverless-observability.md) for details.
