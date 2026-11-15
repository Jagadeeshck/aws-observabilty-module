resource "aws_oam_link" "this" {
  sink_identifier = var.sink_identifier
  label           = var.label
  resource_types  = var.resource_types
  tags            = var.tags
}
