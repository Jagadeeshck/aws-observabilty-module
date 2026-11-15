resource "aws_oam_sink" "this" {
  name = var.name
}

resource "aws_oam_sink_policy" "this" {
  sink_identifier = aws_oam_sink.this.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = var.organization_id == null ? { AWS = var.allowed_account_ids } : "*"
      Action = ["oam:CreateLink", "oam:UpdateLink"]
      Resource = "*"
      Condition = var.organization_id == null ? {} : { "ForAllValues:StringEquals" = { "oam:ResourceTypes" = var.resource_types }, StringEquals = { "aws:PrincipalOrgID" = var.organization_id } }
    }]
  })
}
