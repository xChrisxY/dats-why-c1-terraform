
output "lambda_rds_policy_arn" {
  description = "Lambda RDS policy ARN"
  value       = length(var.rds_resource_arns) > 0 ? aws_iam_policy.lambda_rds[0].arn : null
}

output "lambda_elasticache_policy_arn" {
  description = "Lambda ElastiCache policy ARN"
  value       = length(var.elasticache_resource_arns) > 0 ? aws_iam_policy.lambda_elasticache[0].arn : null
}

output "lambda_secrets_policy_arn" {
  description = "Lambda Secrets policy ARN"
  value       = length(var.secrets_resource_arns) > 0 ? aws_iam_policy.lambda_secrets[0].arn : null
}

output "pdp_lambda_policy_arn" {
  description = "PDP Lambda policy ARN"
  value       = aws_iam_policy.pdp_lambda.arn
}
