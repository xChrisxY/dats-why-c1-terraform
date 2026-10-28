variable "aws_region" {
  description = "AWS region for the backend"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name_prefix" {
  description = "Prefix for S3 bucket and DynamoDB table names"
  type        = string
  default     = "dats-why"
}
