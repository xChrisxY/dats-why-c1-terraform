data "aws_iam_policy_document" "lambda_rds" {
  statement {
    sid    = "RDSConnect"
    effect = "Allow"
    actions = [
      "rds-db:connect"
    ]
    resources = var.rds_resource_arns
  }
}

resource "aws_iam_policy" "lambda_rds" {
  count       = length(var.rds_resource_arns) > 0 ? 1 : 0
  name        = "${var.name_prefix}-lambda-rds-policy"
  description = "Allow Lambda to connect to RDS"
  policy      = data.aws_iam_policy_document.lambda_rds.json

  tags = var.tags
}

data "aws_iam_policy_document" "lambda_elasticache" {
  statement {
    sid    = "ElastiCacheConnect"
    effect = "Allow"
    actions = [
      "elasticache:Connect"
    ]
    resources = var.elasticache_resource_arns
  }
}

resource "aws_iam_policy" "lambda_elasticache" {
  count       = length(var.elasticache_resource_arns) > 0 ? 1 : 0
  name        = "${var.name_prefix}-lambda-elasticache-policy"
  description = "Allow Lambda to connect to ElastiCache"
  policy      = data.aws_iam_policy_document.lambda_elasticache.json

  tags = var.tags
}

data "aws_iam_policy_document" "lambda_secrets" {
  statement {
    sid    = "SecretsRead"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = var.secrets_resource_arns
  }
}

resource "aws_iam_policy" "lambda_secrets" {
  count       = length(var.secrets_resource_arns) > 0 ? 1 : 0
  name        = "${var.name_prefix}-lambda-secrets-policy"
  description = "Allow Lambda to read secrets"
  policy      = data.aws_iam_policy_document.lambda_secrets.json

  tags = var.tags
}

data "aws_iam_policy_document" "pdp_lambda" {
  statement {
    sid    = "RDSAccess"
    effect = "Allow"
    actions = [
      "rds-db:connect"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "SecretsAccess"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = var.secrets_resource_arns
  }

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "pdp_lambda" {
  name        = "${var.name_prefix}-pdp-lambda-policy"
  description = "Policy for PDP Lambda function"
  policy      = data.aws_iam_policy_document.pdp_lambda.json

  tags = var.tags
}
