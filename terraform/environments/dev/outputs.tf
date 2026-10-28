output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.endpoint
}

output "rds_port" {
  description = "RDS port"
  value       = module.rds.port
}

output "redis_endpoint" {
  description = "Redis primary endpoint"
  value       = module.elasticache.primary_endpoint_address
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_client_id" {
  description = "Cognito Client ID"
  value       = module.cognito.client_id
}

output "cognito_domain_url" {
  description = "Cognito domain URL"
  value       = module.cognito.domain_url
}

output "api_invoke_url" {
  description = "API Gateway invoke URL"
  value       = module.api_gateway.invoke_url
}

output "lambda_usuarios_function_name" {
  description = "Usuarios Lambda function name"
  value       = module.lambda_usuarios.function_name
}

output "lambda_orgs_function_name" {
  description = "Orgs Lambda function name"
  value       = module.lambda_orgs.function_name
}

output "lambda_concesiones_function_name" {
  description = "Concesiones Lambda function name"
  value       = module.lambda_concesiones.function_name
}

output "lambda_pdp_function_name" {
  description = "PDP Lambda function name"
  value       = module.lambda_pdp.function_name
}

output "lambda_mtr01_function_name" {
  description = "MTR-01 Lambda function name"
  value       = module.lambda_mtr01.function_name
}

output "lambda_mtr02_function_name" {
  description = "MTR-02 Lambda function name"
  value       = module.lambda_mtr02.function_name
}

output "secrets_arn" {
  description = "Secrets Manager ARN"
  value       = aws_secretsmanager_secret.main.arn
}
