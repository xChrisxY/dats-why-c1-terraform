# Terraform - Dat's Why Platform

## Cimiento 1: Identidad, Organizaciones, Multi-Tenancy y Autorización

Infraestructura como Código (IaC) para el sistema de identidad y autorización multi-tenant de la plataforma Dat's Why.

**Estado del Código:** `terraform validate` → **Success**

---

## Arquitectura Implementada

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          VPC (10.0.0.0/16)                              │
│  ┌────────────────────────┐   ┌────────────────────────────────────┐   │
│  │    Subnets Públicas    │   │         Subnets Privadas           │   │
│  │  ┌─────┐   ┌─────┐    │   │  ┌─────────┐  ┌─────┐  ┌───────┐  │   │
│  │  │ IGW │   │ NAT │    │   │  │ Lambdas │  │ RDS │  │ Redis │  │   │
│  │  │     │   │(off)│    │   │  │   (6)   │  │     │  │       │  │   │
│  │  └─────┘   └─────┘    │   │  └─────────┘  └─────┘  └───────┘  │   │
│  └────────────────────────┘   └────────────────────────────────────┘   │
│                                                                         │
│  VPC Endpoints: secretsmanager, logs                                   │
└─────────────────────────────────────────────────────────────────────────┘

Cognito → API Gateway → Lambdas (usuarios/orgs/concesiones) → PDP → RDS/Redis
                                                              ↑
EventBridge → Lambdas (MTR-01, MTR-02) ──────────────────────┘
```

---

## Estructura del Proyecto

```
terraform/
├── _setup/                    # Backend remoto (S3 + DynamoDB)
│   └── backend/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── modules/                   # Componentes reutilizables
│   ├── vpc/                   # VPC, subnets, IGW, NAT, endpoints
│   ├── rds/                   # PostgreSQL 15.4 + parámetros + alarmas
│   ├── elasticache/           # Redis 7.0 + parámetros + alarmas
│   ├── lambda/                # Función + IAM role + logs
│   ├── cognito/               # User Pool + client + grupos
│   ├── api-gateway/           # REST API + authorizer + CORS + logs
│   ├── eventbridge/           # Schedules + retry + DLQ + alarmas
│   ├── iam/                   # Políticas compartidas
│   └── security-group/        # SGs parametrizables
│
└── environments/              # Configuración por ambiente
    └── dev/
        ├── main.tf            # Orquestación de módulos
        ├── variables.tf       # Variables de entrada
        ├── locals.tf          # Valores derivados
        ├── outputs.tf         # Valores exportados
        ├── providers.tf       # Configuración AWS
        ├── backend.tf         # Configuración de backend remoto
        └── terraform.tfvars   # Valores específicos (sin secretos)
```

---

## Prerrequisitos

| Requisito | Versión Mínima |
|-----------|----------------|
| Terraform | >= 1.0.0 |
| AWS CLI | >= 2.0 |
| AWS Provider | ~> 5.40 |

---

## Inicio Rápido

### 1. Configurar Backend Remoto (solo una vez)

```bash
cd _setup/backend
terraform init
terraform apply

# Guardar los outputs para configurar los environments
```

### 2. Configurar Variables de Entorno

```bash
# Contraseña de base de datos (NUNCA en código)
export TF_VAR_db_password="<password-seguro-aqui>"
```

### 3. Desplegar Ambiente de Desarrollo

```bash
cd environments/dev

# Inicializar (con backend local para pruebas)
terraform init -backend=false

# O con backend remoto (producción)
terraform init \
  -backend-config="bucket=dats-why-terraform-state-ACCOUNT_ID" \
  -backend-config="key=dev/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=dats-why-terraform-locks" \
  -backend-config="encrypt=true"

# Validar configuración
terraform validate

# Ver cambios planeados
terraform plan

# Aplicar cambios
terraform apply
```

---

## Variables de Configuración

### Variables Requeridas

| Variable | Descripción |
|----------|-------------|
| `db_password` | Contraseña del usuario master de PostgreSQL |

### Variables Opcionales

| Variable | Default | Descripción |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | Región de AWS |
| `environment` | `dev` | Nombre del ambiente |
| `project_name` | `dats-why` | Nombre del proyecto |
| `vpc_cidr` | `10.0.0.0/16` | CIDR block del VPC |
| `availability_zones` | `[us-east-1a, us-east-1b]` | Zonas de disponibilidad |
| `db_instance_class` | `db.t3.micro` | Tipo de instancia RDS |
| `redis_node_type` | `cache.t3.micro` | Tipo de nodo ElastiCache |
| `cognito_domain_prefix` | `dats-why-dev` | Prefijo del dominio Cognito |

---

## Outputs Principales

Después de `terraform apply`:

```bash
terraform output
```

| Output | Descripción |
|--------|-------------|
| `api_invoke_url` | URL de la API Gateway |
| `cognito_user_pool_id` | ID del User Pool de Cognito |
| `cognito_client_id` | ID del cliente de la aplicación |
| `cognito_domain_url` | URL para login de Cognito |
| `rds_endpoint` | Endpoint de PostgreSQL |
| `redis_endpoint` | Endpoint de Redis |
| `secrets_arn` | ARN del secreto en Secrets Manager |

---

## Recursos Desplegados

### Red

| Recurso | Nombre | Configuración |
|---------|--------|---------------|
| VPC | `dev-dats-why-vpc` | 10.0.0.0/16, DNS habilitado |
| Internet Gateway | `dev-dats-why-igw` | Adjunto a VPC |
| Subnets Públicas | 2 (1 por AZ) | map_public_ip = true |
| Subnets Privadas | 2 (1 por AZ) | Lambdas, RDS, Redis |
| NAT Gateway | Deshabilitado | VPC Endpoints en su lugar |
| VPC Endpoints | secretsmanager, logs | Acceso privado a servicios AWS |

### Cómputo

| Lambda | Timeout | Memoria | Función |
|--------|---------|---------|---------|
| `dev-dats-why-usuarios` | 30s | 256MB | CRUD usuarios |
| `dev-dats-why-orgs` | 30s | 256MB | CRUD organizaciones |
| `dev-dats-why-concesiones` | 30s | 256MB | CRUD concesiones |
| `dev-dats-why-pdp` | 10s | 512MB | Punto de Decisión |
| `dev-dats-why-mtr01-vencimientos` | 300s | 256MB | Motor vencimientos |
| `dev-dats-why-mtr02-licenciamiento` | 300s | 256MB | Motor licenciamiento |

### Datos

| Servicio | Configuración |
|----------|---------------|
| RDS PostgreSQL 15.4 | db.t3.micro, 20GB gp3, encrypted |
| ElastiCache Redis 7.0 | cache.t3.micro, 1 nodo, encrypted at-rest |

### Identidad y API

| Servicio | Configuración |
|----------|---------------|
| Cognito User Pool | MFA opcional, grupos MO/AG/MA/DW |
| API Gateway REST | Regional, Cognito Authorizer, CORS |

### Automatización

| Schedule | Cron | Lambda |
|----------|------|--------|
| mtr01-schedule | `0 * * * ? *` (cada hora) | lambda_mtr01 |
| mtr02-schedule | `0 6 * * ? *` (06:00 UTC) | lambda_mtr02 |

---

## Seguridad

### Buenas Prácticas Implementadas

- **Secretos:** Nunca en código, usar `TF_VAR_db_password`
- **Estado:** Encriptado en S3 con DynamoDB lock
- **Red:** VPC aislado, subnets privadas para datos
- **IAM:** Roles por Lambda con least privilege
- **Encryption:** At-rest en RDS y Redis

### Security Groups

| SG | Ingress | Uso |
|----|---------|-----|
| `dev-dats-why-lambda-sg` | Ninguno | Lambdas (solo outbound) |
| `dev-dats-why-rds-sg` | 5432 desde VPC | PostgreSQL |
| `dev-dats-why-redis-sg` | 6379 desde VPC | Redis |

---

## Estimación de Costos

### Ambiente de Desarrollo (~$65/mes)

| Servicio | Costo/mes | Notas |
|----------|-----------|-------|
| Cognito | $0 | Free tier 50K MAU |
| API Gateway | $2 | ~1M requests |
| Lambda | $16 | ~2M invocaciones |
| RDS PostgreSQL | $15 | db.t3.micro |
| ElastiCache Redis | $12 | cache.t3.micro |
| VPC Endpoints | $15 | 2 servicios × 1 AZ |
| Secrets Manager | $1 | 1 secreto |
| CloudWatch | $4 | Logs + alarmas |

> **Nota:** VPC Endpoints ($15/mes) reemplazan a NAT Gateway ($32/mes) para acceso a Secrets Manager y CloudWatch Logs desde subnets privadas.

---

## Comandos Útiles

```bash
# Validar sintaxis
terraform validate

# Formatear código
terraform fmt -recursive

# Ver estado actual
terraform state list

# Ver recurso específico
terraform state show module.vpc.aws_vpc.main

# Destruir infraestructura (cuidado!)
terraform destroy
```

---

## Troubleshooting

### Error: "CloudWatch Logs role ARN must be set"

El módulo de API Gateway crea automáticamente el rol necesario. Si el error persiste, verificar que `manage_apigw_account = true` en la configuración.

### Error: "Secrets Manager - unable to connect"

Las Lambdas en VPC privada necesitan acceso a Secrets Manager. Verificar que `enable_vpc_endpoints = true` en el módulo VPC.

### Error: "db_password must be set"

```bash
export TF_VAR_db_password="tu-password-seguro"
```

---

## Referencias

- [Propuesta de Arquitectura](../Propuesta_Arquitectura.md)
- [Diagrama Detallado](../arquitectura.png)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
