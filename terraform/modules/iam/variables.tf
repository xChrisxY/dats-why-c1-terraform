variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "rds_resource_arns" {
  description = "RDS resource ARNs"
  type        = list(string)
  default     = []
}

variable "elasticache_resource_arns" {
  description = "ElastiCache resource ARNs"
  type        = list(string)
  default     = []
}

variable "secrets_resource_arns" {
  description = "Secrets Manager resource ARNs"
  type        = list(string)
  default     = ["*"]
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
