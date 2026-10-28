# Propuesta de Arquitectura: Cimiento 1
## Sistema de Identidad, Organizaciones, Multi-Tenancy y Autorización

**Proyecto:** Dat's Why - Plataforma SaaS para el sector OOH
**ID de Propuesta:** PD-PLAT-C1-v1
**Fecha:** Octubre 2026
**Versión:** 1.1

---

## Tabla de Contenidos

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Objetivo del Cimiento](#objetivo-del-cimiento)
3. [Arquitectura de Alto Nivel](#arquitectura-de-alto-nivel)
4. [Componentes y Decisiones de Diseño](#componentes-y-decisiones-de-diseño)
5. [Modelo de Autorización](#modelo-de-autorización)
6. [Aislamiento Multi-Tenant](#aislamiento-multi-tenant)
7. [Motores Automáticos](#motores-automáticos)
8. [Propuestas para Requisitos Pendientes](#propuestas-para-requisitos-pendientes)
9. [Seguridad](#seguridad)
10. [Observabilidad](#observabilidad)
11. [Estimación de Costos](#estimación-de-costos)
12. [Escalabilidad y Evolución](#escalabilidad-y-evolución)
13. [Estructura del Código](#estructura-del-código)
14. [Guía de Despliegue](#guía-de-despliegue)

---

## Resumen Ejecutivo

Esta propuesta presenta una arquitectura **serverless en AWS** para implementar el Cimiento 1 de la plataforma Dat's Why: un sistema de identidad y autorización multi-tenant que sirve como **punto único de decisión** para toda la plataforma.

### Principios de Diseño

| Principio | Implementación |
|-----------|----------------|
| **Deny by Default** | El PDP rechaza toda operación no explícitamente autorizada |
| **Defensa en Profundidad** | 4 capas de validación: Cognito → API Gateway → PDP → RLS |
| **Aislamiento de Tenants** | Row-Level Security en PostgreSQL + validación en cada capa |
| **Serverless-First** | Cero servidores que administrar, escala automática |
| **Costo Optimizado** | ~$50/mes en MVP, pago por uso real |

### Servicios AWS Utilizados

```
Identidad ........... Amazon Cognito (User Pool)
API ................. API Gateway REST + Lambda
Autorización ........ Lambda PDP + ElastiCache Redis
Datos ............... RDS PostgreSQL con RLS
Automatización ...... EventBridge Scheduler
Secretos ............ Secrets Manager
Observabilidad ...... CloudWatch Logs/Alarms
```

---

## Objetivo del Cimiento

> *"Dar a la plataforma un punto único de decisión de autorización, consumido por la API y por tanto por la interfaz, las integraciones, de modo que ninguna superficie tenga una puerta propia."*

El Cimiento 1 resuelve tres preguntas antes de cada operación:

1. **¿Puede hacerlo?** - Verificar que existe una concesión activa con el rol requerido
2. **¿Qué puede ver?** - Calcular filtros de filas y columnas (RLS)
3. **¿Puede escribir?** - Validar que el campo es editable en este paso del proceso

---

## Arquitectura de Alto Nivel

```
                         ┌──────────────────────────────────────┐
                         │        USUARIOS / INTERNET           │
                         │           HTTPS / OAuth2             │
                         └──────────────────┬───────────────────┘
                                            │
                         ┌──────────────────▼───────────────────┐
                         │         AMAZON COGNITO               │
                         │   User Pool: dev-dats-why-users      │
                         │   • Login por email                  │
                         │   • MFA opcional                     │
                         │   • Claims: tenant_id, org_type      │
                         │   • Grupos: MO / AG / MA / DW        │
                         └──────────────────┬───────────────────┘
                                            │ JWT
                         ┌──────────────────▼───────────────────┐
                         │         API GATEWAY REST             │
                         │   • Authorizer: COGNITO_USER_POOLS   │
                         │   • Stage: v1                        │
                         │   • Access Logs: 14 días             │
                         └──────────────────┬───────────────────┘
                                            │ AWS_PROXY
              ┌─────────────────────────────┼─────────────────────────────┐
              │                             │                             │
    ┌─────────▼─────────┐     ┌─────────────▼───────────┐     ┌──────────▼──────────┐
    │  lambda_usuarios  │     │     lambda_orgs         │     │ lambda_concesiones  │
    │  CRUD usuarios    │     │     CRUD orgs           │     │ CRUD concesiones    │
    │  30s / 256MB      │     │     30s / 256MB         │     │ 30s / 256MB         │
    └─────────┬─────────┘     └───────────┬─────────────┘     └──────────┬──────────┘
              │                           │                              │
              └───────────────────────────┼──────────────────────────────┘
                                          │ authorize()
                         ┌────────────────▼────────────────┐
                         │           PDP Lambda            │
                         │     Punto de Decisión           │
                         │     10s / 512MB / VPC           │
                         │ ─────────────────────────────── │
                         │ 1. ¿Token en blacklist? → DENY  │
                         │ 2. ¿Concesión activa?   → DENY  │
                         │ 3. ¿Rol permite acción? → DENY  │
                         │ 4. ¿Org con entitlement?→ DENY  │
                         │ 5. Calcular filtros RLS         │
                         └──────┬─────────────┬────────────┘
                                │             │
                  ┌─────────────▼──┐     ┌────▼─────────────┐
                  │  REDIS 7.0     │     │  POSTGRESQL 15   │
                  │  cache.t3.micro│     │  db.t3.micro     │
                  │  ──────────────│     │  ────────────────│
                  │  • Blacklist   │     │  • RLS activo    │
                  │  • Sesiones    │     │  • Auditoría     │
                  │  • Cache PDP   │     │  • Fuente verdad │
                  └────────────────┘     └──────────────────┘

    ┌────────────────── CANAL BATCH (EventBridge) ──────────────────┐
    │                                                               │
    │   ┌─────────────────┐          ┌─────────────────┐           │
    │   │ MTR-01 Schedule │          │ MTR-02 Schedule │           │
    │   │ Cada hora       │          │ Diario 06:00    │           │
    │   └────────┬────────┘          └────────┬────────┘           │
    │            │                            │                     │
    │   ┌────────▼────────┐          ┌────────▼────────┐           │
    │   │ lambda_mtr01    │          │ lambda_mtr02    │           │
    │   │ Vencimientos    │          │ Licenciamiento  │           │
    │   │ 300s / 256MB    │          │ 300s / 256MB    │           │
    │   └─────────────────┘          └─────────────────┘           │
    │                                                               │
    └───────────────────────────────────────────────────────────────┘
```

---

## Componentes y Decisiones de Diseño

### 1. Autenticación: Amazon Cognito

| Aspecto | Decisión | Justificación |
|---------|----------|---------------|
| **Servicio** | Cognito User Pool | Integración nativa con API Gateway, Free Tier 50K MAU |
| **Login** | Por email | RF-18: autenticación con correo y contraseña |
| **MFA** | Opcional | Balance entre seguridad y UX para MVP |
| **Atributos custom** | `tenant_id`, `organization_type` | Claims necesarios para multi-tenancy |
| **Grupos** | MO, AG, MA, DW | Clasificación de organización según requisitos |
| **Password** | min 8, mayús, minús, número | Política robusta sin símbolos para usabilidad |
| **Tokens** | access 1h, refresh 30d | Balance seguridad/UX |

**Mapeo a Requisitos:**
- RF-4: Una sola identidad por persona
- RF-18: Autenticación, sesión, SSO, recuperación

### 2. API: API Gateway + Lambda

| Aspecto | Decisión | Justificación |
|---------|----------|---------------|
| **Tipo** | REST Regional | Menor latencia en región principal |
| **Authorizer** | COGNITO_USER_POOLS | Más simple que Lambda Authorizer para MVP |
| **Integración** | AWS_PROXY | Lambda recibe evento completo |
| **Stage** | `v1` | Versionamiento de API |
| **Logs** | 14 días CloudWatch | Cumple RNF-5 (auditoría) |

**Lambdas de Negocio:**

| Lambda | Función | Timeout | Memoria | Requisitos |
|--------|---------|---------|---------|------------|
| `lambda_usuarios` | CRUD usuarios, invitaciones | 30s | 256MB | RF-3, RF-4 |
| `lambda_orgs` | CRUD organizaciones, entitlements | 30s | 256MB | RF-1, RF-2 |
| `lambda_concesiones` | CRUD concesiones, estados | 30s | 256MB | RF-5, RF-6 |

### 3. Autorización: PDP (Punto de Decisión)

El PDP es el corazón del Cimiento 1. Es una Lambda dedicada que:

| Característica | Valor | Razón |
|----------------|-------|-------|
| **Timeout** | 10s | Es camino crítico, debe ser rápido |
| **Memoria** | 512MB | Más CPU para decisiones rápidas |
| **Concurrencia** | Provisioned en prod | Eliminar cold starts |
| **VPC** | Privada | Acceso directo a Redis y RDS |

**Flujo de Decisión:**

```python
def authorize(context):
    # 1. ¿Token revocado?
    if redis.exists(f"blacklist:{token_jti}"):
        return DENY(401, "Token revocado")

    # 2. ¿Concesión activa?
    grant = cache_or_db("grants", tenant_id, user_id)
    if not grant or grant.status != "ACTIVA":
        return DENY(403, "Sin concesión activa")

    # 3. ¿Rol permite la acción?
    if action not in ROLE_PERMISSIONS[grant.role]:
        return DENY(403, "Rol no autorizado")

    # 4. ¿Organización tiene entitlement?
    entitlements = cache_or_db("entitlements", org_id)
    if required_capability not in entitlements:
        return DENY(403, "Capacidad no licenciada")

    # 5. Calcular filtros RLS
    return ALLOW(filters={
        "tenant_id": tenant_id,
        "org_ids": allowed_orgs,
        "columns": allowed_columns
    })
```

**Mapeo a Requisitos:**
- RF-7: Derivar alcance de datos en cada apertura
- RF-8: Resolver las 3 preguntas
- RF-9: Distinguir origen de escritura
- RF-10: Ocultar campos de metodología
- RNF-2.1: Rechazar si PDP no responde

### 4. Cache: ElastiCache Redis

| Aspecto | Decisión | Justificación |
|---------|----------|---------------|
| **Versión** | 7.0 | Última versión estable |
| **Tipo** | cache.t3.micro | Suficiente para MVP |
| **Nodos** | 1 | Sin HA en dev |
| **Encryption** | At-rest ON, Transit OFF | Balance seguridad/rendimiento |
| **Eviction** | allkeys-lru | Liberar memoria automáticamente |

**Estrategia de TTL:**

| Dato | TTL | Razón |
|------|-----|-------|
| Token blacklist | 24h | Igual a expiración JWT |
| Concesiones | 30s | RNF-4: delay < 30s para revocaciones |
| Entitlements | 5min | Cambio infrecuente |
| Catálogo roles | 1h | Solo cambia con deploys |

**Mapeo a Requisitos:**
- RNF-4: Retraso entre acto y efecto < 30s (TTL corto + invalidación)

### 5. Base de Datos: RDS PostgreSQL

| Aspecto | Decisión | Justificación |
|---------|----------|---------------|
| **Versión** | 15.4 | Row-Level Security maduro |
| **Tipo** | db.t3.micro | Suficiente para MVP |
| **Storage** | 20GB gp3, autoscale 100GB | Crecimiento sin intervención |
| **Encryption** | Habilitada | Datos sensibles |
| **Multi-AZ** | No (dev) | Costo; habilitar en prod |
| **Backups** | 7 días | Recuperación de datos |

**Parámetros de Auditoría:**
```
log_statement = all           # RF-11: auditoría completa
log_min_duration_statement = 1000  # Queries lentas
pg_stat_statements            # Análisis de rendimiento
```

**Row-Level Security:**
```sql
CREATE POLICY tenant_isolation ON grants
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
```

**Mapeo a Requisitos:**
- RNF-6: Aislamiento entre clientes (RLS)
- RNF-7: Campos de metodología no expuestos

---

## Modelo de Autorización

### Estructura de Tres Ejes

```
Autorización = Clasificación × Rol Base × Ámbito
```

| Clasificación | Roles Disponibles |
|---------------|-------------------|
| MO (Media Owner) | Titular, consulta, operador, autorizador, auditor |
| AG (Agencia) | Titular, consulta, operador, autorizador, auditor |
| MA (Marca) | Titular, consulta, operador, autorizador, auditor |
| DW (Dat's Why) | admin |

### Estados de Concesión

```
SOLICITADA → AUTORIZADA → ACTIVA → VENCIDA
                ↓           ↓
            RECHAZADA   SUSPENDIDA → RETIRADA
```

Transiciones automáticas por motores:
- MTR-01: ACTIVA → VENCIDA (cuando expira vigencia)
- MTR-02: ACTIVA → SUSPENDIDA (cuando pierde entitlements)

**Mapeo a Requisitos:**
- RF-5: Crear concesión con vigencia y rol
- RF-11: Bitácora de cambios de estado
- RF-12: Vencimiento automático (MTR-01)
- RF-13: Suspensión automática (MTR-02)
- RF-15: Cambio de rol crea nueva concesión

---

## Aislamiento Multi-Tenant

### Defensa en Profundidad (4 Capas)

```
Request
   │
   ▼
┌──────────────────────────────────────────────────────────┐
│ CAPA 1: Cognito Authorizer                               │
│ • Valida JWT                                             │
│ • Extrae tenant_id del claim custom:tenant_id            │
└──────────────────────┬───────────────────────────────────┘
                       │
┌──────────────────────▼───────────────────────────────────┐
│ CAPA 2: Lambda Middleware                                │
│ • Valida que usuario pertenece al tenant                 │
│ • Propaga tenant_id al contexto                          │
└──────────────────────┬───────────────────────────────────┘
                       │
┌──────────────────────▼───────────────────────────────────┐
│ CAPA 3: PDP                                              │
│ • Verifica concesión activa en ese tenant                │
│ • Calcula filtros de datos                               │
└──────────────────────┬───────────────────────────────────┘
                       │
┌──────────────────────▼───────────────────────────────────┐
│ CAPA 4: PostgreSQL RLS                                   │
│ • Filtra filas automáticamente por tenant_id             │
│ • Última línea de defensa                                │
└──────────────────────────────────────────────────────────┘
```

**Resultado:** Incluso si 3 capas fallan, la base de datos previene fugas de datos.

---

## Motores Automáticos

### MTR-01: Vencimiento de Concesiones

| Aspecto | Valor |
|---------|-------|
| **Frecuencia** | Cada hora (`cron(0 * * * ? *)`) |
| **Timeout** | 300s (procesamiento batch) |
| **Función** | Marcar concesiones expiradas como VENCIDA |
| **Principal** | `MOTOR_ID=MTR-01` |

```python
# Pseudocódigo MTR-01
def handler(event):
    concesiones = db.query("""
        SELECT * FROM concesiones
        WHERE estado = 'ACTIVA'
        AND vigencia_fin < NOW()
    """)

    for c in concesiones:
        db.execute("""
            UPDATE concesiones SET estado = 'VENCIDA'
            WHERE id = %s
        """, c.id)

        # RF-11: Bitácora
        db.execute("""
            INSERT INTO bitacora_concesion
            (concesion_id, actor, timestamp, estado_origen, estado_destino, motivo)
            VALUES (%s, 'MTR-01', NOW(), 'ACTIVA', 'VENCIDA', 'vigencia_vencida')
        """, c.id)
```

### MTR-02: Suspensión por Licenciamiento

| Aspecto | Valor |
|---------|-------|
| **Frecuencia** | Diario 06:00 UTC (`cron(0 6 * * ? *)`) |
| **Timeout** | 300s |
| **Función** | Suspender concesiones sin entitlements |
| **Principal** | `MOTOR_ID=MTR-02` |

**Mapeo a Requisitos:**
- RF-12: Vencimiento sin intervención
- RF-13: Suspensión por capacidades vacías
- RF-16: Principal de servicio con credenciales en Secrets Manager

---

## Propuestas para Requisitos Pendientes

### RNF-1: Latencia del PDP

| Propuesta | Valor | Cómo lograrlo |
|-----------|-------|---------------|
| P99 | < 50ms | Cache Redis + Provisioned Concurrency |
| P95 | < 30ms | 80-90% cache hit |

### RNF-2: Disponibilidad del PDP

| Propuesta | Valor | Cómo lograrlo |
|-----------|-------|---------------|
| Sistema | 99.9% | Lambda HA por defecto |
| PDP | 99.95% | Provisioned Concurrency + Multi-AZ |

### RNF-3: Volumen MVP

| Métrica | Propuesta |
|---------|-----------|
| Organizaciones | 20 |
| Usuarios/org | ~7 (150 total) |
| Concesiones | ~500 (múltiples por usuario) |
| Requests/segundo | 10 (pico) |

### RNF-4: Delay de Revocación

| Propuesta | Valor | Implementación |
|-----------|-------|----------------|
| Máximo | 30 segundos | Cache TTL 30s + invalidación activa |

### RNF-8: i18n

| Propuesta | Implementación |
|-----------|----------------|
| Idiomas iniciales | Español (MX), Inglés (US) |
| Monedas | MXN (piloto), USD |
| Husos horarios | America/Mexico_City |

### RNF-10: Husos Horarios

| Propuesta | Implementación |
|-----------|----------------|
| Vigencias | Se evalúan a las 00:00 del huso del mercado de la org |
| Storage | UTC en base de datos |
| Display | Convertir al huso del usuario |

---

## Seguridad

### Medidas Implementadas

| Capa | Medida |
|------|--------|
| **Red** | VPC privada, subnets aisladas |
| **Tránsito** | HTTPS obligatorio |
| **Datos** | Encryption at-rest (RDS, Redis) |
| **Secretos** | Secrets Manager (no en código) |
| **Acceso** | IAM roles por Lambda (least privilege) |
| **Tokens** | Blacklist en Redis para revocación |

### Security Groups

| SG | Ingress | Uso |
|----|---------|-----|
| lambda-sg | Ninguno | Lambdas solo hacen outbound |
| rds-sg | 5432 desde VPC | PostgreSQL |
| redis-sg | 6379 desde VPC | Redis |

### Pendiente (Fase 2)

- **WAF:** Web Application Firewall para API Gateway
- **Transit Encryption:** TLS para Redis

---

## Observabilidad

### Logs

| Componente | Log Group | Retención |
|------------|-----------|-----------|
| API Gateway | `/aws/api-gateway/dev-dats-why-api` | 14 días |
| Lambdas | `/aws/lambda/{function-name}` | 14 días |
| RDS | Deshabilitado en dev | - |

### Alarmas CloudWatch

| Recurso | Alarma | Umbral |
|---------|--------|--------|
| RDS | CPU High | > 80% |
| RDS | Storage Low | < 5 GB |
| Redis | CPU High | > 75% |
| Redis | Memory High | > 80% |
| EventBridge | Failed Invocations | > 0 |

### Pendiente (Fase 2)

- **SNS:** Notificaciones de alarmas
- **X-Ray:** Trazas distribuidas
- **Performance Insights:** Análisis RDS

---

## Estimación de Costos

### MVP (Dev)

| Servicio | Costo/mes | Notas |
|----------|-----------|-------|
| Cognito | $0 | Free tier 50K MAU |
| API Gateway | $2 | ~1M requests |
| Lambda | $16 | ~2M invocaciones |
| RDS PostgreSQL | $15 | db.t3.micro |
| ElastiCache Redis | $12 | cache.t3.micro |
| VPC Endpoints | $15 | 2 interfaces |
| Secrets Manager | $1 | 1 secreto |
| CloudWatch | $4 | Logs/alarmas |
| **Total** | **~$65/mes** | |

### Producción (Estimado)

| Servicio | Costo/mes |
|----------|-----------|
| RDS Multi-AZ | $50 |
| Redis con réplica | $30 |
| Provisioned Concurrency | $20 |
| WAF | $10 |
| **Total** | **~$150-200/mes** |

---

## Escalabilidad y Evolución

### Crecimiento sin Rediseño

| Escenario | Acción |
|-----------|--------|
| 1K organizaciones | Upgrade a Aurora PostgreSQL |
| 10K usuarios | Aumentar Provisioned Concurrency |
| Alta latencia | Habilitar Redis réplica + Multi-AZ |
| Ultra-baja latencia | Migrar PDP a ECS + OPA sidecar |

### Roadmap de Mejoras

| Fase | Mejora |
|------|--------|
| Fase 2 | WAF, SNS, X-Ray |
| Fase 3 | Aurora, Redis Cluster |
| Fase 4 | OPA Policy Engine |

---

## Estructura del Código

```
terraform/
├── _setup/                    # Bootstrap: backend S3 + DynamoDB
│   └── backend/
├── modules/                   # Componentes reutilizables
│   ├── vpc/                   # VPC, subnets, endpoints
│   ├── rds/                   # PostgreSQL + alarmas
│   ├── elasticache/           # Redis + alarmas
│   ├── lambda/                # Función + rol + logs
│   ├── cognito/               # User Pool + grupos
│   ├── api-gateway/           # REST API + authorizer
│   ├── eventbridge/           # Schedules + alarmas
│   ├── security-group/        # SGs parametrizables
│   └── iam/                   # Políticas compartidas
└── environments/
    └── dev/                   # Configuración de desarrollo
        ├── main.tf            # Orquestación de módulos
        ├── variables.tf       # Variables de entrada
        ├── locals.tf          # Valores derivados
        ├── outputs.tf         # Valores exportados
        ├── providers.tf       # Configuración AWS
        └── terraform.tfvars   # Valores específicos
```

---

## Guía de Despliegue

### Prerrequisitos

```bash
# AWS CLI configurado
aws configure

# Terraform >= 1.0.0
terraform --version
```

### Variables de Entorno

```bash
# Contraseña de base de datos (no en código)
export TF_VAR_db_password="<password-seguro>"
```

### Comandos

```bash
cd terraform/environments/dev

# Inicializar (primera vez)
terraform init

# Ver cambios
terraform plan

# Aplicar
terraform apply

# Ver outputs
terraform output
```

### Outputs Principales

| Output | Descripción |
|--------|-------------|
| `api_invoke_url` | URL de la API |
| `cognito_domain_url` | URL de login Cognito |
| `rds_endpoint` | Endpoint PostgreSQL |
| `redis_endpoint` | Endpoint Redis |

---

## Anexos

### A. Mapeo de Requisitos a Implementación

| Requisito | Implementación |
|-----------|----------------|
| RF-1 | `lambda_orgs` + validación enum en DB |
| RF-2 | RBAC: solo DW admin modifica entitlements |
| RF-3, RF-4 | `lambda_usuarios` + Cognito |
| RF-5, RF-6 | `lambda_concesiones` + PDP |
| RF-7, RF-8 | PDP + RLS |
| RF-9 | Claims de origen en PDP |
| RF-10 | Column-level filtering en PDP |
| RF-11 | Tabla `bitacora_concesion` |
| RF-12, RF-13 | MTR-01, MTR-02 |
| RF-14 | Redis blacklist + invalidación |
| RF-15 | Soft delete + nueva concesión |
| RF-16 | Secrets Manager + IAM |
| RF-18 | Cognito |

### B. Diferencias con Propuesta Original

| Aspecto | Propuesta Original | Implementación |
|---------|-------------------|----------------|
| Authorizer | Lambda Authorizer | Cognito User Pool Authorizer |
| NAT Gateway | Requerido | VPC Endpoints (más económico) |
| WAF | Incluido | Fase 2 |
| SNS | Incluido | Fase 2 |

Las diferencias son decisiones conscientes para optimizar el MVP manteniendo la capacidad de escalar.

---

**Documento preparado para:** Dat's Why
**Validación técnica:** `terraform validate` → Success
**Estado del código:** Listo para despliegue en ambiente de desarrollo
