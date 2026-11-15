import json
import os

import boto3


def _region_from_arn(arn):
    parts = arn.split(":", 5)
    if len(parts) < 6 or not parts[3]:
        raise ValueError(f"Expected a regional AWS ARN, got: {arn}")
    return parts[3]


def _enable_lambda(item):
    arn = item["resource_arn"]
    client = boto3.client("lambda", region_name=_region_from_arn(arn))
    current = client.get_function_configuration(FunctionName=arn)
    mode = current.get("TracingConfig", {}).get("Mode", "PassThrough")
    if mode != "Active":
        client.update_function_configuration(FunctionName=arn, TracingConfig={"Mode": "Active"})
    return {"service": "lambda", "key": item["key"], "resource_arn": arn, "status": "enabled" if mode != "Active" else "already_enabled"}


def _enable_stepfunctions(item):
    arn = item["resource_arn"]
    client = boto3.client("stepfunctions", region_name=_region_from_arn(arn))
    current = client.describe_state_machine(stateMachineArn=arn)
    if current.get("tracingConfiguration", {}).get("enabled", False):
        return {"service": "stepfunctions", "key": item["key"], "resource_arn": arn, "status": "already_enabled"}
    client.update_state_machine(stateMachineArn=arn, tracingConfiguration={"enabled": True})
    return {"service": "stepfunctions", "key": item["key"], "resource_arn": arn, "status": "enabled"}


def _enable_apigateway_rest(item):
    client = boto3.client("apigateway", region_name=item["region"])
    current = client.get_stage(restApiId=item["rest_api_id"], stageName=item["stage_name"])
    if current.get("tracingEnabled", False):
        status = "already_enabled"
    else:
        client.update_stage(
            restApiId=item["rest_api_id"],
            stageName=item["stage_name"],
            patchOperations=[{"op": "replace", "path": "/tracingEnabled", "value": "true"}],
        )
        status = "enabled"
    return {"service": "apigateway_rest", "key": item["key"], "rest_api_id": item["rest_api_id"], "stage_name": item["stage_name"], "status": status}


def lambda_handler(event, context):
    if os.environ.get("ENABLE_XRAY_TRACING", "false").lower() != "true":
        return {"status": "disabled", "results": []}

    resources = json.loads(os.environ.get("NATIVE_RESOURCES", "[]"))
    handlers = {
        "lambda": _enable_lambda,
        "stepfunctions": _enable_stepfunctions,
        "apigateway_rest": _enable_apigateway_rest,
    }
    results = []
    for item in resources:
        try:
            handler = handlers[item["service"]]
            results.append(handler(item))
        except Exception as exc:  # report failures but continue processing other allowlisted resources
            results.append({"service": item.get("service"), "key": item.get("key"), "status": "error", "error": str(exc)[:500]})
    return {"status": "complete", "results": results}
