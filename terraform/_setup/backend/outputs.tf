output "s3_bucket_name" {
  description = "S3 bucket name for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "backend_config" {
  description = "Backend configuration for use in other environments"
  value       = <<-EOT

    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.terraform_state.id}"
        key            = "ENV_NAME/terraform.tfstate"  # Replace ENV_NAME
        region         = "${data.aws_region.current.name}"
        dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
        encrypt        = true
      }
    }

    terraform init \\
      -backend-config="bucket=${aws_s3_bucket.terraform_state.id}" \\
      -backend-config="key=dev/terraform.tfstate" \\
      -backend-config="region=${data.aws_region.current.name}" \\
      -backend-config="dynamodb_table=${aws_dynamodb_table.terraform_locks.name}" \\
      -backend-config="encrypt=true"

  EOT
}
