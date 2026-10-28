
variable "user_pool_name" {
  description = "User pool name"
  type        = string
}

variable "username_attributes" {
  description = "Attributes for username"
  type        = list(string)
  default     = ["email"]
}

variable "auto_verified_attributes" {
  description = "Auto-verified attributes"
  type        = list(string)
  default     = ["email"]
}

variable "password_minimum_length" {
  description = "Minimum password length"
  type        = number
  default     = 8
}

variable "password_require_lowercase" {
  description = "Require lowercase"
  type        = bool
  default     = true
}

variable "password_require_numbers" {
  description = "Require numbers"
  type        = bool
  default     = true
}

variable "password_require_symbols" {
  description = "Require symbols"
  type        = bool
  default     = false
}

variable "password_require_uppercase" {
  description = "Require uppercase"
  type        = bool
  default     = true
}

variable "temporary_password_validity_days" {
  description = "Temporary password validity in days"
  type        = number
  default     = 7
}

variable "mfa_configuration" {
  description = "MFA configuration (OFF, ON, OPTIONAL)"
  type        = string
  default     = "OPTIONAL"
}

variable "advanced_security_mode" {
  description = "Advanced security mode (OFF, AUDIT, ENFORCED)"
  type        = string
  default     = "OFF"
}

variable "explicit_auth_flows" {
  description = "Explicit auth flows"
  type        = list(string)
  default = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}

variable "callback_urls" {
  description = "Callback URLs"
  type        = list(string)
  default     = ["http://localhost:3000/callback"]
}

variable "logout_urls" {
  description = "Logout URLs"
  type        = list(string)
  default     = ["http://localhost:3000/logout"]
}

variable "access_token_validity_hours" {
  description = "Access token validity in hours"
  type        = number
  default     = 1
}

variable "id_token_validity_hours" {
  description = "ID token validity in hours"
  type        = number
  default     = 1
}

variable "refresh_token_validity_days" {
  description = "Refresh token validity in days"
  type        = number
  default     = 30
}

variable "read_attributes" {
  description = "Read attributes"
  type        = list(string)
  default     = ["email", "custom:tenant_id", "custom:organization_type"]
}

variable "write_attributes" {
  description = "Write attributes"
  type        = list(string)
  default     = ["email"]
}

variable "domain_prefix" {
  description = "Cognito domain prefix"
  type        = string
}

variable "user_groups" {
  description = "User groups to create"
  type        = list(string)
  default     = ["MO", "AG", "MA", "DW"]
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
