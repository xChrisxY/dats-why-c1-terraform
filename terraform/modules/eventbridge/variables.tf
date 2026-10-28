
variable "rule_name" {
  description = "EventBridge rule name"
  type        = string
}

variable "description" {
  description = "Rule description"
  type        = string
  default     = "Scheduled rule"
}

variable "schedule_expression" {
  description = "Schedule expression (cron or rate)"
  type        = string
}

variable "is_enabled" {
  description = "Is rule enabled"
  type        = bool
  default     = true
}

variable "target_lambda_arn" {
  description = "Target Lambda ARN"
  type        = string
}

variable "target_lambda_function_name" {
  description = "Target Lambda function name"
  type        = string
}

variable "max_event_age_seconds" {
  description = "Maximum event age in seconds"
  type        = number
  default     = 3600
}

variable "max_retry_attempts" {
  description = "Maximum retry attempts"
  type        = number
  default     = 2
}

variable "dlq_arn" {
  description = "Dead letter queue ARN"
  type        = string
  default     = null
}

variable "create_alarm" {
  description = "Create CloudWatch alarm"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
