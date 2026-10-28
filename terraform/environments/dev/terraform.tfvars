# General
aws_region   = "us-east-1"
environment  = "dev"
project_name = "dats-why"

# Networking
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# Database
db_instance_class = "db.t3.micro"
db_name           = "datswhy"
db_username       = "datswhy_admin"
# db_password     = "CHANGE_ME" # Usar variable de entorno TF_VAR_db_password

# Cache
redis_node_type = "cache.t3.micro"

# Cognito
cognito_domain_prefix = "dats-why-dev"
