import importlib.util
import unittest
from pathlib import Path

SPEC = importlib.util.spec_from_file_location("normalize", Path(__file__).parents[1] / "scripts" / "normalize_otel_inventory.py")
module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(module)


class NormalizeInventoryTest(unittest.TestCase):
    def test_maps_standard_cloud_and_service_attributes(self):
        result = module.normalize({
            "account_id": "123456789012",
            "region": "eu-west-1",
            "resource_id": "i-abc123",
            "resource_type": "AWS::EC2::Instance",
            "service_name": "orders",
            "environment": "prod",
        })
        attrs = result["resource"]
        self.assertEqual(attrs["cloud.provider"], "aws")
        self.assertEqual(attrs["cloud.account.id"], "123456789012")
        self.assertEqual(attrs["cloud.region"], "eu-west-1")
        self.assertEqual(attrs["host.id"], "i-abc123")
        self.assertEqual(attrs["service.name"], "orders")
        self.assertEqual(attrs["deployment.environment.name"], "prod")
        self.assertEqual(attrs["aws.resource.id"], "i-abc123")

    def test_custom_resource_state_is_namespaced_and_tag_allowlisted(self):
        result = module.normalize({
            "resource_id": "fn",
            "resource_type": "AWS::Lambda::Function",
            "observability": {"tracing_enabled": True, "logs_enabled": False},
            "tags": {"team": "data", "secret": "do-not-export"},
            "otel_tag_allowlist": ["team"],
        })
        attrs = result["resource"]
        self.assertTrue(attrs["aws.observability.tracing.enabled"])
        self.assertFalse(attrs["aws.observability.logs.enabled"])
        self.assertEqual(attrs["aws.tag.team"], "data")
        self.assertNotIn("aws.tag.secret", attrs)

    def test_missing_optional_metadata_is_ok(self):
        self.assertEqual(module.normalize({})["resource"], {"cloud.provider": "aws"})


if __name__ == "__main__":
    unittest.main()
