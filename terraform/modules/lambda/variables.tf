
variable "function_name" {
  description = "Lambda function name"
  type        = string
}

variable "role_name" {
  description = "IAM role name"
  type        = string
}

variable "handler" {
  description = "Function handler"
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Runtime"
  type        = string
  default     = "python3.11"
}

variable "timeout" {
  description = "Timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Memory in MB"
  type        = number
  default     = 256
}

variable "filename" {
  description = "Path to deployment package"
  type        = string
}

variable "source_code_hash" {
  description = "Base64-encoded SHA256 hash of package"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "vpc_subnet_ids" {
  description = "VPC subnet IDs"
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "VPC security group IDs"
  type        = list(string)
  default     = []
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions"
  type        = number
  default     = -1
}

variable "provisioned_concurrent_executions" {
  description = "Provisioned concurrency (eliminates cold starts)"
  type        = number
  default     = 0
}

variable "tracing_mode" {
  description = "X-Ray tracing mode"
  type        = string
  default     = "PassThrough"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "invoke_principal" {
  description = "Principal allowed to invoke (e.g., apigateway.amazonaws.com)"
  type        = string
  default     = null
}

variable "invoke_source_arn" {
  description = "Source ARN for invoke permission"
  type        = string
  default     = null
}

variable "custom_policy" {
  description = "Custom IAM policy JSON"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
