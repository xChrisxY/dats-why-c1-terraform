
locals {
  name_prefix = "${var.environment}-${var.project_name}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  vpc_name = "${local.name_prefix}-vpc"

  db_identifier = "${local.name_prefix}-postgres"

  redis_cluster_id = "${local.name_prefix}-redis"

  user_pool_name = "${local.name_prefix}-users"

  lambda_usuarios_name    = "${local.name_prefix}-usuarios"
  lambda_orgs_name        = "${local.name_prefix}-orgs"
  lambda_concesiones_name = "${local.name_prefix}-concesiones"
  pdp_function_name       = "${local.name_prefix}-pdp"
  mtr01_function_name     = "${local.name_prefix}-mtr01-vencimientos"
  mtr02_function_name     = "${local.name_prefix}-mtr02-licenciamiento"

  api_name = "${local.name_prefix}-api"

  secrets_name = "${local.name_prefix}-secrets"
}
