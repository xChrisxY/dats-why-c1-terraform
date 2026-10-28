output "endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.endpoint
}

output "address" {
  description = "RDS hostname"
  value       = aws_db_instance.main.address
}

output "port" {
  description = "RDS port"
  value       = aws_db_instance.main.port
}

output "identifier" {
  description = "RDS identifier"
  value       = aws_db_instance.main.identifier
}

output "arn" {
  description = "RDS ARN"
  value       = aws_db_instance.main.arn
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}
