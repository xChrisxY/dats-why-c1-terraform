variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = false
}

variable "enable_vpc_endpoints" {
  description = "Create interface VPC endpoints for Secrets Manager and CloudWatch Logs"
  type        = bool
  default     = true
}

variable "vpc_endpoint_services" {
  description = "Interface VPC endpoint service names (short form)"
  type        = list(string)
  default     = ["secretsmanager", "logs"]
}

variable "vpc_endpoint_subnet_count" {
  description = "Number of private subnets (AZs) where interface endpoints are created. 1 = cheaper (dev), 2 = HA (prod)."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
