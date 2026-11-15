output "sink_arn" {
  description = "OAM sink ARN for source-account links."
  value       = aws_oam_sink.this.arn
}
output "sink_id" {
  value = aws_oam_sink.this.id
}
