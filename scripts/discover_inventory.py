# Source the AWS Config aggregator inventory with boto3 and emit Terraform tfvars JSON.
# Usage: python scripts/discover_inventory.py --aggregator-name org-inventory --regions us-east-1,us-west-2 --output examples/selected-services/inventory.auto.tfvars.json
# Requires AWS credentials allowed to call config:SelectAggregateResourceConfig in the aggregator account.
import argparse
import json
from pathlib import Path

# Resource types queried by service. Config coverage varies by resource type and region.
RESOURCE_TYPES = {
    "ec2": ["AWS::EC2::Instance"],
    "rds": ["AWS::RDS::DBInstance", "AWS::RDS::DBCluster"],
    "ecs": ["AWS::ECS::Cluster", "AWS::ECS::Service"],
    "lambda": ["AWS::Lambda::Function"],
    "emr": ["AWS::EMR::Cluster"],
    "sagemaker": ["AWS::SageMaker::Domain", "AWS::SageMaker::NotebookInstance", "AWS::SageMaker::Endpoint", "AWS::SageMaker::TrainingJob"],
    "bedrock": ["AWS::Bedrock::Agent", "AWS::Bedrock::KnowledgeBase", "AWS::Bedrock::Guardrail"],
    "agentcore": [],  # AgentCore inventory support depends on AWS Config resource-type coverage; supply supported IDs manually when unavailable.
    "s3": ["AWS::S3::Bucket"],
    "s3_tables": [],  # S3 Tables Config coverage varies; provide inventory manually until your Config recorder reports these resource types.
    "athena": ["AWS::Athena::WorkGroup"],
    "glue": ["AWS::Glue::Database", "AWS::Glue::Job", "AWS::Glue::Crawler"],
    "datazone": ["AWS::DataZone::Domain", "AWS::DataZone::Project"],
    "dynamodb": ["AWS::DynamoDB::Table"],
    "opensearch": ["AWS::OpenSearch::Domain"],
    "iam": ["AWS::IAM::Role", "AWS::IAM::User", "AWS::IAM::Policy"],
    "route53": ["AWS::Route53::HostedZone", "AWS::Route53::HealthCheck"],
}

# Only use metrics with a known, stable resource dimension. Other resources are
# inventoried with no default alarms so teams can add accurate per-service specs.
DIMENSION_BY_TYPE = {
    "AWS::EC2::Instance": ("InstanceId", "resourceId"),
    "AWS::RDS::DBInstance": ("DBInstanceIdentifier", "resourceId"),
    "AWS::RDS::DBCluster": ("DBClusterIdentifier", "resourceId"),
    "AWS::Lambda::Function": ("FunctionName", "resourceId"),
    "AWS::DynamoDB::Table": ("TableName", "resourceId"),
    "AWS::OpenSearch::Domain": ("DomainName", "resourceId"),
}
BASELINE_ALARMS = {
    "AWS::EC2::Instance": [{"name_suffix":"status-check-failed","namespace":"AWS/EC2","metric_name":"StatusCheckFailed","statistic":"Maximum","period":300,"evaluation_periods":2,"threshold":0,"comparison_operator":"GreaterThanThreshold","treat_missing_data":"notBreaching"}],
    "AWS::RDS::DBInstance": [{"name_suffix":"cpu-high","namespace":"AWS/RDS","metric_name":"CPUUtilization","statistic":"Average","period":300,"evaluation_periods":3,"threshold":80,"comparison_operator":"GreaterThanThreshold","treat_missing_data":"missing"}],
    "AWS::Lambda::Function": [{"name_suffix":"errors","namespace":"AWS/Lambda","metric_name":"Errors","statistic":"Sum","period":300,"evaluation_periods":1,"threshold":1,"comparison_operator":"GreaterThanOrEqualToThreshold","treat_missing_data":"notBreaching"}],
    "AWS::DynamoDB::Table": [{"name_suffix":"system-errors","namespace":"AWS/DynamoDB","metric_name":"SystemErrors","statistic":"Sum","period":300,"evaluation_periods":1,"threshold":1,"comparison_operator":"GreaterThanOrEqualToThreshold","treat_missing_data":"notBreaching"}],
}


def main():
    parser = argparse.ArgumentParser(description="Export supported AWS Config aggregator resources to observability Terraform inventory.")
    parser.add_argument("--aggregator-name", required=True)
    parser.add_argument("--regions", default="", help="Comma-separated regions to include; empty means all aggregator regions.")
    parser.add_argument("--services", default=",".join(RESOURCE_TYPES), help="Comma-separated service keys.")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    import boto3
    client = boto3.client("config")
    selected = [s.strip() for s in args.services.split(",") if s.strip()]
    unknown = set(selected) - set(RESOURCE_TYPES)
    if unknown:
        raise SystemExit(f"Unsupported service keys: {', '.join(sorted(unknown))}")
    regions = [r.strip() for r in args.regions.split(",") if r.strip()]
    inventory = {service: {} for service in selected}
    for service in selected:
        for resource_type in RESOURCE_TYPES[service]:
            query = f"SELECT accountId, awsRegion, resourceId, resourceType WHERE resourceType = '{resource_type}'"
            if regions:
                region_predicate = " OR ".join(f"awsRegion = '{region}'" for region in regions)
                query += f" AND ({region_predicate})"
            token = None
            while True:
                request = {"Expression": query, "ConfigurationAggregatorName": args.aggregator_name, "Limit": 100}
                if token:
                    request["NextToken"] = token
                response = client.select_aggregate_resource_config(**request)
                for raw in response.get("Results", []):
                    row = json.loads(raw)
                    rid = row["resourceId"]
                    account = row.get("accountId", "unknown")
                    region = row.get("awsRegion", "unknown")
                    key = f"{account}-{region}-{rid}".replace(":", "-").replace("/", "-")
                    dimension = DIMENSION_BY_TYPE.get(resource_type)
                    dimensions = {dimension[0]: rid} if dimension else {}
                    alarms = []
                    for spec in BASELINE_ALARMS.get(resource_type, []):
                        alarm = {k: v for k, v in spec.items() if k != "name_suffix"}
                        alarm["name"] = f"{service}-{key}-{spec['name_suffix']}"[:255]
                        alarms.append(alarm)
                    inventory[service][key] = {"dimensions": dimensions, "alarms": alarms, "metadata": {"account_id": account, "region": region, "resource_type": resource_type, "resource_id": rid}}
                token = response.get("NextToken")
                if not token:
                    break
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps({"resource_inventory": inventory}, indent=2) + "\n")
    print(f"Wrote inventory for {sum(len(v) for v in inventory.values())} resources to {output}")

if __name__ == "__main__":
    main()
