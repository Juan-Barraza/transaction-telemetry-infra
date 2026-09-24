# AWS IaC Laboratory - Modular Infrastructure with Terraform

## Propósito del Proyecto

Este laboratorio fue diseñado como un entorno práctico, educativo e interactivo para implementar Infraestructura como Código (IaC) en Amazon Web Services (AWS) utilizando Terraform. El objetivo principal es desplegar una arquitectura base modular de microservicios alineada con las mejores prácticas del sector, priorizando:

- **Optimización de Costos:** Totalmente compatible con la Capa Gratuita de AWS (Free Tier) utilizando instancias `t3.micro` o `t2.micro`.
- **Ciclo de Vida Efímero:** Capacidad de aprovisionar y destruir entornos completos en cuestión de minutos para evitar costos no deseados tras completar sesiones de estudio.
- **Seguridad y Modularidad:** Aislamiento de responsabilidades mediante módulos reutilizables, políticas de menor privilegio con roles IAM y gestión nativa del estado de Terraform.

---

## Arquitectura Desplegada

La infraestructura despliega una VPC con subred pública, un backend remoto en S3, una tabla de DynamoDB y 4 servidores EC2 independientes dedicados a cargas de trabajo específicas:

```text
                          AWS Region (us-east-1)
  ┌──────────────────────────────────────────────────────────────────────────────┐
  │ VPC (10.0.0.0/16)                                                            │
  │                                                                              │
  │  Public Subnet (10.0.1.0/24) + Internet Gateway                              │
  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌────────────┐ │
  │  │ Jenkins Server  │ │ Telemetry Serv. │ │ Account Service │ │ Database   │ │
  │  │  (Port 22,8080) │ │(22, 8081, 9090) │ │  (Port 22,8080) │ │(5432, 6379)│ │
  │  └────────┬────────┘ └────────┬────────┘ └─────────────────┘ └────────────┘ │
  └───────────┼───────────────────┼──────────────────────────────────────────────┘
              │                   │ (IAM Role Profile)
              │                   ▼
   ┌──────────┴────────┐   ┌───────────────────────────┐
   │ S3 State Bucket   │   │ DynamoDB (Telemetry)      │
   │ (use_lockfile)    │   │ (accountId + timestamp)   │
   └───────────────────┘   └───────────────────────────┘
```

- **Jenkins Server:** Instancia para la ejecución de pipelines de CI/CD.
- **Telemetry Service:** Microservicio configurado con un IAM Instance Profile para lectura/escritura segura en DynamoDB sin credenciales quemadas.
- **Account Service:** Microservicio de dominio expuesto para peticiones API.
- **Database Node:** Servidor aislado con puertos autorizados exclusivamente a nivel de red interna para PostgreSQL y Redis.

---

## Tecnologías Utilizadas y Justificación

| Tecnología | Rol en el Proyecto | Justificación |
|---|---|---|
| AWS (us-east-1) | Proveedor Cloud | Estándar global con amplia cobertura en la capa gratuita y baja latencia de despliegue. |
| Terraform (v1.10+) | Herramienta de IaC | Permite definir la infraestructura mediante código declarativo, versionable y reproducible. |
| S3 + Native Lock | Remote Backend | Guarda el `.tfstate` de manera remota. Usa el flag `use_lockfile = true` para el bloqueo de estado nativo de S3, reduciendo costos y eliminando la necesidad de tablas adicionales en DynamoDB. |
| Ubuntu 24.04 LTS | Sistema Operativo | SO ligero y estable, ideal para ejecutar contenedores Docker con actualizaciones a largo plazo. |
| Dynamic Blocks | Refactorización HCL | Automatiza la creación de reglas de entrada (ingress) en los Security Groups mediante listas de puertos dinámicas. |
| IAM Instance Profiles | Seguridad | Otorga a la instancia de Telemetría acceso a DynamoDB por tokens temporales (AWS STS) de manera transparente. |
| Docker & Docker Compose | Runtime de Contenedores | Aprovisionado de forma automatizada mediante scripts de `user_data` al inicializar las instancias. |

---

## Qué Problema Resolvemos

En entornos de aprendizaje tradicionales es común configurar recursos manualmente a través de la consola web de AWS. Esto genera varios problemas:

- **"Snowflake Servers":** Servidores únicos configurados a mano que son imposibles de recrear de forma exacta si fallan.
- **Costos Fantasma:** Olvidar apagar o borrar recursos al finalizar el laboratorio genera cobros imprevistos.
- **Falta de Aislamiento:** Usar el mismo Security Group para todos los servidores compromete la seguridad y la arquitectura.

### Solución Implementada

Con este laboratorio:

- **Toda la infraestructura se define en código:** La VPC, subredes, grupos de seguridad, llaves, permisos y servidores se crean con una sola línea de comando (`terraform apply`).
- **Destrucción total controlada:** Con ejecutar `terraform destroy` se garantiza la limpieza del 100% de los recursos en AWS, manteniendo la factura en cero.

---

## Estructura del Proyecto

```text
.
├── bootstrap/                      # Provisionamiento inicial del estado remoto
│   ├── main.tf                     # Bucket S3 con versionamiento y cifrado
│   ├── variables.tf
│   └── outputs.tf
│
└── infrastructure/                 # Infraestructura principal
    ├── main.tf                     # Invocación de módulos y configuración de proveedores
    ├── variables.tf                # Definición global de variables
    ├── terraform.tfvars            # Valores del entorno (no subir a git si contiene datos sensibles)
    ├── backend.tfvars              # Configuración dinámica del backend S3
    │
    ├── modules/
    │   ├── vpc/                    # Redes, subredes, tablas de ruteo e IGW
    │   │   ├── main.tf             # 4 Security Groups con dynamic ingress
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   │
    │   ├── ec2/                    # Despliegue de los 4 servidores
    │   │   ├── main.tf             # Instancias EC2, IAM Roles y Storage
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   │
    │   └── dynamodb/               # Tabla de persistencia para Telemetría
    │       ├── main.tf
    │       ├── variables.tf
    │       └── outputs.tf
    │
    └── scripts/
        └── init-docker.sh          # Bootstrap Script para docker/docker-compose
```

---

## Guía de Despliegue Paso a Paso

### Prerrequisitos

- AWS CLI configurado con `aws configure`.
- Terraform v1.10.0 o superior instalado.
- Key Pair creado previa o dinámicamente en tu cuenta de AWS.

### Paso 1: Inicializar el Bootstrap (Estado Remoto)

```bash
cd bootstrap
terraform init
terraform apply
```

Toma nota del nombre del bucket S3 generado en los outputs.

### Paso 2: Configurar y Desplegar la Infraestructura

Navega a la carpeta principal de la infraestructura:

```bash
cd ../infrastructure
```

Crea o edita el archivo `backend.tfvars`:

```hcl
bucket       = "TU_BUCKET_NAME_GENERADO"
key          = "dev/infrastructure/terraform.tfstate"
region       = "us-east-1"
use_lockfile = true
encrypt      = true
```

Inicializa Terraform vinculando el backend remoto:

```bash
terraform init -reconfigure -backend-config="backend.tfvars"
```

### Paso 3: Planificar y Aplicar

```bash
# Verificar la creación de los recursos
terraform plan

# Desplegar la infraestructura completa
terraform apply
```

### Paso 4: Conexión por SSH a las Instancias

Asigna los permisos necesarios a tu archivo `.pem` antes de conectarte:

```bash
ssh -i keys.pem ubuntu@<IP_PUBLICA_EC2>
```

---

## Limpieza del Laboratorio

Para evitar cargos no deseados en la cuenta de AWS, destruye la infraestructura al terminar la sesión de pruebas:

```bash
# Destruir servidores, VPC, DynamoDB y recursos asociados
terraform destroy
```

---

## Valor de Aprendizaje

Aunque la escala de esta infraestructura es pequeña, aborda patrones arquitectónicos esenciales para proyectos de producción:

- **Inyección de scripts mediante User Data:** Automatiza el aprovisionamiento de software desde el primer arranque del sistema.
- **Integración IAM + EC2:** Demuestra cómo evitar el uso de credenciales estáticas dentro de las aplicaciones mediante el uso de Instance Profiles.
- **Nativo vs Deprecado en IaC:** Evolución en la gestión del bloqueo de estado con el mecanismo nativo `use_lockfile` en S3.