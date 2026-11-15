#!/usr/bin/env python3
"""Normalize AWS inventory into OTel resource attributes without inventing telemetry.

Input is a JSON list of inventory objects, e.g. resource-inventory.json. This tool
only shapes metadata; it never calls AWS or enables monitoring.
"""
import argparse
import json
from pathlib import Path
from typing import Any


def normalize(item: dict[str, Any]) -> dict[str, Any]:
    account_id = item.get("account_id")
    region = item.get("region")
    resource_id = item.get("resource_id")
    resource_type = item.get("resource_type")

    attrs: dict[str, Any] = {"cloud.provider": "aws"}
    if account_id:
        attrs["cloud.account.id"] = str(account_id)
    if region:
        attrs["cloud.region"] = str(region)
    if item.get("availability_zone"):
        attrs["cloud.availability_zone"] = item["availability_zone"]
    if item.get("cloud.platform"):
        attrs["cloud.platform"] = item["cloud.platform"]
    if item.get("service_name"):
        attrs["service.name"] = item["service_name"]
    if item.get("service_namespace"):
        attrs["service.namespace"] = item["service_namespace"]
    if item.get("environment"):
        attrs["deployment.environment.name"] = item["environment"]
    if resource_id:
        # AWS resource inventory identifiers are not universally represented by
        # one stable OTel semantic-convention attribute; keep this project-scoped.
        attrs["aws.resource.id"] = str(resource_id)
        if resource_type == "AWS::EC2::Instance":
            attrs["host.id"] = str(resource_id)
    if resource_type:
        attrs["aws.resource.type"] = str(resource_type)
    if item.get("observability"):
        state = item["observability"]
        mapping = {
            "metrics_enabled": "aws.observability.metrics.enabled",
            "logs_enabled": "aws.observability.logs.enabled",
            "tracing_enabled": "aws.observability.tracing.enabled",
            "detailed_monitoring_enabled": "aws.observability.detailed_monitoring.enabled",
        }
        for input_key, output_key in mapping.items():
            if input_key in state and state[input_key] is not None:
                attrs[output_key] = bool(state[input_key])
    if item.get("source"):
        attrs["aws.observability.source"] = str(item["source"])

    # Tags are opt-in: callers must provide tag_keys, preventing accidental
    # export of all user tags, sensitive values, or high-cardinality data.
    allowed_tag_keys = set(item.get("otel_tag_allowlist", []))
    for key, value in (item.get("tags") or {}).items():
        if key in allowed_tag_keys and value is not None:
            attrs[f"aws.tag.{key}"] = str(value)

    return {
        "resource": attrs,
        "inventory": {
            key: value for key, value in item.items()
            if key not in {"tags", "otel_tag_allowlist", "service_name", "service_namespace", "environment", "cloud.platform", "availability_zone", "observability", "source"}
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, help="JSON file containing a list of AWS resource inventory objects")
    parser.add_argument("--output", required=True, help="Output JSON file")
    args = parser.parse_args()
    records = json.loads(Path(args.input).read_text())
    if not isinstance(records, list):
        raise SystemExit("Input JSON must be a list of resource objects")
    normalized = [normalize(record) for record in records]
    Path(args.output).write_text(json.dumps(normalized, indent=2, sort_keys=True) + "\n")


if __name__ == "__main__":
    main()
