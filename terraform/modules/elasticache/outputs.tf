
output "primary_endpoint_address" {
  description = "Primary endpoint address"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader endpoint address"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.main.port
}

output "arn" {
  description = "Replication group ARN"
  value       = aws_elasticache_replication_group.main.arn
}

output "id" {
  description = "Replication group ID"
  value       = aws_elasticache_replication_group.main.id
}
