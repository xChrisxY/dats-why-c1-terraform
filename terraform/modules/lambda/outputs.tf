output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.main.function_name
}

output "arn" {
  description = "Lambda ARN"
  value       = aws_lambda_function.main.arn
}

output "invoke_arn" {
  description = "Lambda invoke ARN"
  value       = aws_lambda_function.main.invoke_arn
}

output "qualified_arn" {
  description = "Lambda qualified ARN with version"
  value       = aws_lambda_function.main.qualified_arn
}

output "version" {
  description = "Lambda version"
  value       = aws_lambda_function.main.version
}

output "role_arn" {
  description = "IAM role ARN"
  value       = aws_iam_role.lambda.arn
}

output "role_name" {
  description = "IAM role name"
  value       = aws_iam_role.lambda.name
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.main.name
}
