variable "enabled" {
  type = bool
  default = true
}
variable "name" {
  type = string
  default = "otel-gateway"
}
variable "image" {
  description = "Pinned ADOT Collector image URI or tag. Pin a production image to a tested version/digest."
  type = string
  default = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
}
variable "subnet_ids" { type = list(string) }
variable "vpc_id" { type = string }
variable "allowed_cidr_blocks" {
  description = "CIDRs allowed to send OTLP to the gateway. Restrict to source VPC/network ranges."
  type = list(string)
}
variable "listener_port" { type = number default = 4317 }
variable "tags" { type = map(string) default = {} }
