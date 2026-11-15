import json
import os
from typing import Any, Dict, List

import boto3


def _safe_json(value):
    try:
        return json.loads(json.dumps(value))
    except Exception:
        return value


def _get_function_state(function):
    state = {
        "function_name": function.get("FunctionName"),
        "runtime": function.get("Runtime"),
        "version": function.get("Version"),
        "state": function.get("State"),
        "last_modified": function.get("LastModified"),
        "tracing_mode": function.get("TracingConfig", {}).get("Mode"),
        "logging_config": function.get("LoggingConfig"),
        "observability_ready": function.get("TracingConfig", {}).get("Mode") == "Active",
    }
    return state


def _get_ec2_inventory():
    client = boto3.client("ec2")
    response = client.describe_instances()
    inventory = []
    for reservation in response.get("Reservations", []):
        for instance in reservation.get("Instances", []):
            monitoring_state = instance.get("Monitoring", {}).get("State", "disabled")
            inventory.append({
                "resource_id": instance.get("InstanceId"),
                "resource_type": "ec2",
                "name": instance.get("Tags", [{}])[0].get("Value") if instance.get("Tags") else None,
                "region": os.environ.get("AWS_REGION"),
                "status": instance.get("State", {}).get("Name"),
                "monitoring": {
                    "detailed_monitoring": monitoring_state == "enabled",
                    "state": monitoring_state,
                },
                "observability": {
                    "cloudwatch_metrics": True,
                    "logs": bool(instance.get("IamInstanceProfile")),
                    "enabled": monitoring_state == "enabled",
                },
            })
    return inventory


def _get_rds_inventory():
    client = boto3.client("rds")
    response = client.describe_db_instances()
    inventory = []
    for db in response.get("DBInstances", []):
        inventory.append({
            "resource_id": db.get("DBInstanceIdentifier"),
            "resource_type": "rds",
            "region": os.environ.get("AWS_REGION"),
            "status": db.get("DBInstanceStatus"),
            "monitoring": {
                "performance_insights": db.get("PerformanceInsightsEnabled", False),
                "enhanced_monitoring": bool(db.get("EnhancedMonitoringResourceArn")),
            },
            "observability": {
                "cloudwatch_metrics": True,
                "logs": True,
                "enabled": db.get("PerformanceInsightsEnabled", False),
            },
        })
    return inventory


def _get_lambda_inventory():
    client = boto3.client("lambda")
    response = client.list_functions()
    inventory = []
    for function in response.get("Functions", []):
        detail = client.get_function(FunctionName=function["FunctionName"])
        cfg = detail.get("Configuration", {})
        inventory.append({
            "resource_id": cfg.get("FunctionName"),
            "resource_type": "lambda",
            "region": os.environ.get("AWS_REGION"),
            "runtime": cfg.get("Runtime"),
            "tracing_mode": cfg.get("TracingConfig", {}).get("Mode"),
            "logging": cfg.get("LoggingConfig"),
            "observability": {
                "cloudwatch_metrics": True,
                "tracing_enabled": cfg.get("TracingConfig", {}).get("Mode") == "Active",
                "logs_enabled": bool(cfg.get("LoggingConfig")),
                "enabled": cfg.get("TracingConfig", {}).get("Mode") == "Active",
            },
        })
    return inventory


def _get_s3_inventory():
    client = boto3.client("s3")
    response = client.list_buckets()
    inventory = []
    for bucket in response.get("Buckets", []):
        name = bucket["Name"]
        try:
            logging = client.get_bucket_logging(Bucket=name)
            logging_enabled = bool(logging.get("LoggingEnabled"))
        except Exception:
            logging_enabled = False
        inventory.append({
            "resource_id": name,
            "resource_type": "s3",
            "region": os.environ.get("AWS_REGION"),
            "status": "active",
            "monitoring": {"access_logging": logging_enabled},
            "observability": {"cloudwatch_metrics": True, "logs_enabled": logging_enabled, "enabled": logging_enabled},
        })
    return inventory


def _get_config_inventory():
    try:
        client = boto3.client("config")
        response = client.list_discovered_resources(maxResults=100)
        return response.get("resourceIdentifiers", [])
    except Exception:
        return []


def _enable_lambda_tracing(function_name):
    client = boto3.client("lambda")
    client.update_function_configuration(
        FunctionName=function_name,
        TracingConfig={"Mode": "Active"},
    )


def _enable_ec2_detailed_monitoring(instance_id):
    client = boto3.client("ec2")
    client.monitor_instances(InstanceIds=[instance_id])


def _enable_rds_performance_insights(db_instance_id):
    client = boto3.client("rds")
    client.modify_db_instance(
        DBInstanceIdentifier=db_instance_id,
        EnablePerformanceInsights=True,
        PerformanceInsightsRetentionPeriod=7,
    )


def _apply_supported_enablement(service_name: str, resource_id: str):
    if service_name == "lambda":
        _enable_lambda_tracing(resource_id)
    elif service_name == "ec2":
        _enable_ec2_detailed_monitoring(resource_id)
    elif service_name == "rds":
        _enable_rds_performance_insights(resource_id)


def _inventory_by_service(service_names):
    lookup = {
        "ec2": _get_ec2_inventory,
        "rds": _get_rds_inventory,
        "lambda": _get_lambda_inventory,
        "s3": _get_s3_inventory,
    }
    inventory = {}
    for service in service_names:
        func = lookup.get(service)
        if func:
            inventory[service] = func()
    return inventory


def _store_report(report):
    bucket = os.environ.get("REPORT_BUCKET_NAME")
    if bucket:
        import datetime
        client = boto3.client("s3")
        key = f"{os.environ.get('REPORT_S3_PREFIX', 'aws-observability-discovery/')}{datetime.datetime.utcnow().strftime('%Y/%m/%d/%H%M%S')}.json"
        client.put_object(Bucket=bucket, Key=key, Body=json.dumps(report, default=str).encode("utf-8"))
    return True


def _publish_report(report):
    topic = os.environ.get("REPORT_TOPIC_ARN")
    if topic:
        boto3.client("sns").publish(
            TopicArn=topic,
            Subject="aws-observability-discovery",
            Message=json.dumps(report, default=str),
        )


def lambda_handler(event, context):
    services = [s.strip() for s in os.environ.get("SERVICES", "").split(",") if s.strip()]
    if not services:
        services = ["ec2", "rds", "lambda", "s3"]

    inventory = _inventory_by_service(services)
    inventory["aws_config"] = _get_config_inventory()

    report = {
        "account_id": boto3.client("sts").get_caller_identity()["Account"],
        "region": os.environ.get("AWS_REGION"),
        "timestamp": __import__("datetime").datetime.utcnow().isoformat() + "Z",
        "services": inventory,
        "enable_observability": os.environ.get("ENABLE_OBSERVABILITY", "false").lower() == "true",
    }

    if os.environ.get("ENABLE_OBSERVABILITY", "false").lower() == "true":
        settings = json.loads(os.environ.get("OBSERVABILITY_SETTINGS", "{}"))
        for service, service_settings in settings.items():
            if not service_settings.get("enabled"):
                continue
            for resource in inventory.get(service, []):
                if resource.get("resource_id"):
                    try:
                        _apply_supported_enablement(service, resource["resource_id"])
                    except Exception:
                        pass

    _store_report(report)
    _publish_report(report)
    return report

