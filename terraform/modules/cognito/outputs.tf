
output "user_pool_id" {
  description = "User pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "User pool ARN"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "User pool endpoint"
  value       = aws_cognito_user_pool.main.endpoint
}

output "client_id" {
  description = "User pool client ID"
  value       = aws_cognito_user_pool_client.main.id
}

output "domain" {
  description = "Cognito domain"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "domain_url" {
  description = "Cognito domain URL"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
}

data "aws_region" "current" {}
