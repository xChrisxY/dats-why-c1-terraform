
variable "api_name" {
  description = "API Gateway name"
  type        = string
}

variable "description" {
  description = "API description"
  type        = string
  default     = "Dat's Why API"
}

variable "stage_name" {
  description = "Stage name"
  type        = string
  default     = "v1"
}

variable "lambda_invoke_arn" {
  description = "Lambda invoke ARN"
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
}

variable "authorization_type" {
  description = "Authorization type (NONE, COGNITO_USER_POOLS, CUSTOM)"
  type        = string
  default     = "COGNITO_USER_POOLS"
}

variable "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  type        = string
  default     = null
}

variable "lambda_authorizer_uri" {
  description = "Lambda authorizer invoke URI"
  type        = string
  default     = null
}

variable "authorizer_ttl_seconds" {
  description = "Authorizer cache TTL"
  type        = number
  default     = 300
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "routes" {
  description = "Additional top-level routes mapped to Lambda functions"
  type = list(object({
    path_part         = string
    lambda_invoke_arn = string
  }))
  default = []
}

variable "manage_apigw_account" {
  description = "Crear el rol de cuenta necesario para que API Gateway escriba en CloudWatch Logs"
  type        = bool
  default     = true
}
