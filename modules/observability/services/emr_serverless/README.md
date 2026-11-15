# Amazon EMR Serverless observability is built on CloudWatch metrics and EventBridge job state notifications.
#
# Use `AWS/EMRServerless` metrics for application/job resource usage; use EventBridge for
# run lifecycle state transitions (pending/running/succeeded/failed/cancelled).
#
# Example:
# resource_inventory = {
#   emr_serverless = {
#     analytics_app = {
#       dimensions = {
#         ApplicationId = "application-id"
#       }
#       alarms = [
#         {
#           name = "emr-serverless-cpu-high"
#           namespace = "AWS/EMRServerless"
#           metric_name = "WorkerCpuUsed"
#           statistic = "Maximum"
#           period = 300
#           evaluation_periods = 3
#           threshold = 80
#           comparison_operator = "GreaterThanThreshold"
#         }
#       ]
#     }
#   }
# }
