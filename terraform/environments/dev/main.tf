module "vpc" {
  source = "../../modules/vpc"

  cidr_block         = var.vpc_cidr
  availability_zones = var.availability_zones
  environment        = var.environment
  project_name       = var.project_name
  enable_nat_gateway = false # Deshabilitado en dev para ahorrar costos (usamos VPC endpoints)

  # Acceso privado a Secrets Manager y CloudWatch Logs sin NAT
  enable_vpc_endpoints = true

  tags = local.common_tags
}

module "sg_rds" {
  source = "../../modules/security-group"

  name        = "${local.name_prefix}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
      description = "PostgreSQL from VPC"
    }
  ]

  tags = local.common_tags
}

module "sg_redis" {
  source = "../../modules/security-group"

  name        = "${local.name_prefix}-redis-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
      description = "Redis from VPC"
    }
  ]

  tags = local.common_tags
}

module "sg_lambda" {
  source = "../../modules/security-group"

  name        = "${local.name_prefix}-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [] # Lambda no necesita ingress

  tags = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  identifier     = local.db_identifier
  engine_version = "15.4"
  instance_class = var.db_instance_class

  database_name   = var.db_name
  master_username = var.db_username
  master_password = var.db_password

  db_subnet_group_name   = module.vpc.db_subnet_group_name
  vpc_security_group_ids = [module.sg_rds.id]

  multi_az                = false
  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = local.common_tags
}

module "elasticache" {
  source = "../../modules/elasticache"

  cluster_id     = local.redis_cluster_id
  engine_version = "7.0"
  node_type      = var.redis_node_type

  subnet_group_name  = module.vpc.elasticache_subnet_group_name
  security_group_ids = [module.sg_redis.id]

  num_cache_nodes            = 1
  automatic_failover_enabled = false
  multi_az_enabled           = false

  tags = local.common_tags
}

module "cognito" {
  source = "../../modules/cognito"

  user_pool_name = local.user_pool_name
  domain_prefix  = var.cognito_domain_prefix

  password_minimum_length    = 8
  password_require_lowercase = true
  password_require_numbers   = true
  password_require_symbols   = false
  password_require_uppercase = true

  mfa_configuration = "OPTIONAL"

  callback_urls = ["http://localhost:3000/callback"]
  logout_urls   = ["http://localhost:3000/logout"]

  user_groups = ["MO", "AG", "MA", "DW"]

  tags = local.common_tags
}

data "archive_file" "lambda_placeholder" {
  type        = "zip"
  output_path = "${path.module}/lambda_placeholder.zip"

  source {
    content  = <<-EOF
      def handler(event, context):
          return {
              'statusCode': 200,
              'body': 'Placeholder - Replace with actual code'
          }
    EOF
    filename = "index.py"
  }
}

module "lambda_pdp" {
  source = "../../modules/lambda"

  function_name = local.pdp_function_name
  role_name     = "${local.pdp_function_name}-role"
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 10 # PDP debe ser rápido
  memory_size   = 512

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  provisioned_concurrent_executions = 0 # Habilitar en prod

  environment_variables = {
    ENVIRONMENT = var.environment
    DB_HOST     = module.rds.address
    DB_NAME     = var.db_name
    REDIS_HOST  = module.elasticache.primary_endpoint_address
    REDIS_PORT  = "6379"
    SECRETS_ARN = aws_secretsmanager_secret.main.arn
  }

  vpc_subnet_ids         = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.sg_lambda.id]

  tags = local.common_tags
}

module "lambda_mtr01" {
  source = "../../modules/lambda"

  function_name = local.mtr01_function_name
  role_name     = "${local.mtr01_function_name}-role"
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 300 # 5 minutos para procesar batch
  memory_size   = 256

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment_variables = {
    ENVIRONMENT = var.environment
    DB_HOST     = module.rds.address
    DB_NAME     = var.db_name
    REDIS_HOST  = module.elasticache.primary_endpoint_address
    REDIS_PORT  = "6379"
    MOTOR_ID    = "MTR-01"
    SECRETS_ARN = aws_secretsmanager_secret.main.arn
  }

  vpc_subnet_ids         = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.sg_lambda.id]

  tags = local.common_tags
}

module "lambda_mtr02" {
  source = "../../modules/lambda"

  function_name = local.mtr02_function_name
  role_name     = "${local.mtr02_function_name}-role"
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 300
  memory_size   = 256

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment_variables = {
    ENVIRONMENT = var.environment
    DB_HOST     = module.rds.address
    DB_NAME     = var.db_name
    REDIS_HOST  = module.elasticache.primary_endpoint_address
    REDIS_PORT  = "6379"
    MOTOR_ID    = "MTR-02"
    SECRETS_ARN = aws_secretsmanager_secret.main.arn
  }

  vpc_subnet_ids         = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.sg_lambda.id]

  tags = local.common_tags
}

module "api_gateway" {
  source = "../../modules/api-gateway"

  api_name    = local.api_name
  description = "Dat's Why Platform API - ${var.environment}"
  stage_name  = "v1"

  lambda_invoke_arn    = module.lambda_usuarios.invoke_arn
  lambda_function_name = module.lambda_usuarios.function_name

  authorization_type    = "COGNITO_USER_POOLS"
  cognito_user_pool_arn = module.cognito.user_pool_arn

  routes = [
    {
      path_part         = "usuarios"
      lambda_invoke_arn = module.lambda_usuarios.invoke_arn
    },
    {
      path_part         = "orgs"
      lambda_invoke_arn = module.lambda_orgs.invoke_arn
    },
    {
      path_part         = "concesiones"
      lambda_invoke_arn = module.lambda_concesiones.invoke_arn
    },
  ]

  tags = local.common_tags
}

module "eventbridge_mtr01" {
  source = "../../modules/eventbridge"

  rule_name           = "${local.name_prefix}-mtr01-schedule"
  description         = "Schedule for MTR-01 - Vencimiento de concesiones"
  schedule_expression = "cron(0 * * * ? *)" # Cada hora

  target_lambda_arn           = module.lambda_mtr01.arn
  target_lambda_function_name = module.lambda_mtr01.function_name

  tags = local.common_tags
}

module "eventbridge_mtr02" {
  source = "../../modules/eventbridge"

  rule_name           = "${local.name_prefix}-mtr02-schedule"
  description         = "Schedule for MTR-02 - Suspensión por licenciamiento"
  schedule_expression = "cron(0 6 * * ? *)" # Cada día a las 6am UTC

  target_lambda_arn           = module.lambda_mtr02.arn
  target_lambda_function_name = module.lambda_mtr02.function_name

  tags = local.common_tags
}

module "iam" {
  source = "../../modules/iam"

  name_prefix           = local.name_prefix
  secrets_resource_arns = [aws_secretsmanager_secret.main.arn]

  tags = local.common_tags
}

# AWS SECRETS MANAGER
resource "aws_secretsmanager_secret" "main" {
  name        = local.secrets_name
  description = "Secrets for Dat's Why C1 - ${var.environment}"

  # Dev: borrado inmediato para poder recrear sin chocar con la ventana de recuperación
  recovery_window_in_days = 0

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "main" {
  secret_id = aws_secretsmanager_secret.main.id
  secret_string = jsonencode({
    db_username = var.db_username
    db_password = var.db_password
  })
}

# LAMBDAS DE NEGOCIO (Separadas según Sección 5)
module "lambda_usuarios" {
  source = "../../modules/lambda"

  function_name = local.lambda_usuarios_name
  role_name     = "${local.lambda_usuarios_name}-role"
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 256

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment_variables = {
    ENVIRONMENT = var.environment
    DB_HOST     = module.rds.address
    DB_NAME     = var.db_name
    REDIS_HOST  = module.elasticache.primary_endpoint_address
    REDIS_PORT  = "6379"
    SECRETS_ARN = aws_secretsmanager_secret.main.arn
  }

  vpc_subnet_ids         = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.sg_lambda.id]

  tags = local.common_tags
}

module "lambda_orgs" {
  source = "../../modules/lambda"

  function_name = local.lambda_orgs_name
  role_name     = "${local.lambda_orgs_name}-role"
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 256

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment_variables = {
    ENVIRONMENT = var.environment
    DB_HOST     = module.rds.address
    DB_NAME     = var.db_name
    REDIS_HOST  = module.elasticache.primary_endpoint_address
    REDIS_PORT  = "6379"
    SECRETS_ARN = aws_secretsmanager_secret.main.arn
  }

  vpc_subnet_ids         = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.sg_lambda.id]

  tags = local.common_tags
}

module "lambda_concesiones" {
  source = "../../modules/lambda"

  function_name = local.lambda_concesiones_name
  role_name     = "${local.lambda_concesiones_name}-role"
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 256

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment_variables = {
    ENVIRONMENT = var.environment
    DB_HOST     = module.rds.address
    DB_NAME     = var.db_name
    REDIS_HOST  = module.elasticache.primary_endpoint_address
    REDIS_PORT  = "6379"
    SECRETS_ARN = aws_secretsmanager_secret.main.arn
  }

  vpc_subnet_ids         = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.sg_lambda.id]

  tags = local.common_tags
}

# lambda_usuarios ya recibe permiso dentro de module.api_gateway
# (aws_lambda_permission.api_gateway), por eso no se duplica aquí.

resource "aws_lambda_permission" "apigw_orgs" {
  statement_id  = "AllowAPIGatewayInvokeOrgs"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_orgs.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_concesiones" {
  statement_id  = "AllowAPIGatewayInvokeConcesiones"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_concesiones.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.execution_arn}/*/*"
}

# IAM POLICY ATTACHMENTS
# asociadas a ningún rol. Se adjuntan aquí.
resource "aws_iam_role_policy_attachment" "usuarios_secrets" {
  role       = module.lambda_usuarios.role_name
  policy_arn = module.iam.lambda_secrets_policy_arn
}

resource "aws_iam_role_policy_attachment" "orgs_secrets" {
  role       = module.lambda_orgs.role_name
  policy_arn = module.iam.lambda_secrets_policy_arn
}

resource "aws_iam_role_policy_attachment" "concesiones_secrets" {
  role       = module.lambda_concesiones.role_name
  policy_arn = module.iam.lambda_secrets_policy_arn
}

resource "aws_iam_role_policy_attachment" "pdp_secrets" {
  role       = module.lambda_pdp.role_name
  policy_arn = module.iam.lambda_secrets_policy_arn
}

resource "aws_iam_role_policy_attachment" "pdp_custom" {
  role       = module.lambda_pdp.role_name
  policy_arn = module.iam.pdp_lambda_policy_arn
}

resource "aws_iam_role_policy_attachment" "mtr01_secrets" {
  role       = module.lambda_mtr01.role_name
  policy_arn = module.iam.lambda_secrets_policy_arn
}

resource "aws_iam_role_policy_attachment" "mtr02_secrets" {
  role       = module.lambda_mtr02.role_name
  policy_arn = module.iam.lambda_secrets_policy_arn
}
