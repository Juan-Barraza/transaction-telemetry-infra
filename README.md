# AWS IaC Laboratory - Modular Infrastructure with Terraform

## Propósito del Proyecto

Este laboratorio fue diseñado como un entorno práctico, educativo e interactivo para implementar Infraestructura como Código (IaC) en Amazon Web Services (AWS) utilizando Terraform. El objetivo principal es desplegar una arquitectura base modular de microservicios y su flujo de CI/CD, priorizando:

- **Optimización de Costos:** Compatible con la Capa Gratuita de AWS (Free Tier) usando instancias `t3.micro` o `t2.micro` (ver [recomendaciones de tamaño](#tamaño-de-instancias)).
- **Ciclo de Vida Efímero:** Capacidad de aprovisionar y destruir entornos completos en minutos para evitar costos no deseados.
- **Seguridad y Modularidad:** Módulos reutilizables, roles IAM de menor privilegio, acceso a las instancias por **AWS Systems Manager (SSM)** en lugar de SSH, y gestión nativa del estado de Terraform.
- **Despliegue continuo:** Jenkins construye y publica imágenes en Docker Hub (CI) y despliega en las instancias mediante SSM (CD).

---

## Arquitectura Desplegada

La infraestructura despliega una VPC con subred pública, un backend remoto en S3, una tabla de DynamoDB y 4 servidores EC2 independientes:

```text
                          AWS Region (us-east-1)
  ┌──────────────────────────────────────────────────────────────────────────────┐
  │ VPC (10.0.0.0/16)                                                            │
  │                                                                              │
  │  Public Subnet (10.0.1.0/24) + Internet Gateway                              │
  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌────────────┐ │
  │  │ Jenkins Server  │ │ Telemetry Serv. │ │ Account Service │ │ Database   │ │
  │  │  (Port 8080)    │ │  (8081, 9090)   │ │  (Port 8080)    │ │(5432, 6379)│ │
  │  └───┬─────────────┘ └────────▲────────┘ └────────▲────────┘ └────────────┘ │
  └──────┼────────────────────────┼───────────────────┼─────────────────────────┘
         │  aws ssm send-command  │                   │
         └────────────────────────┴───────────────────┘
         │
         ▼
   ┌───────────────┐    docker pull     ┌───────────────────────────┐
   │ Docker Hub    │ ◄───────────────── │ Instancias (deploy.sh)    │
   └───────────────┘                    └───────────────────────────┘

   ┌───────────────────┐   ┌───────────────────────────┐
   │ S3 State Bucket   │   │ DynamoDB (Telemetry)      │
   │ (use_lockfile)    │   │ (accountId + timestamp)   │
   └───────────────────┘   └───────────────────────────┘
```

| Instancia | Rol | IAM Role |
|---|---|---|
| **Jenkins** | CI/CD (Jenkins en Docker) | SSM + permiso `ssm:SendCommand` para desplegar |
| **Telemetry** | Microservicio WebFlux + gRPC | SSM + acceso a DynamoDB |
| **Account** | Microservicio de dominio (Spring Web + JPA) | Solo SSM |
| **Database** | PostgreSQL + Redis con Docker Compose | Solo SSM |

---

## Tecnologías Utilizadas y Justificación

| Tecnología | Rol en el Proyecto | Justificación |
|---|---|---|
| AWS (us-east-1) | Proveedor Cloud | Estándar global con amplia cobertura en la capa gratuita. |
| Terraform (v1.10+) | Herramienta de IaC | Infraestructura declarativa, versionable y reproducible. |
| S3 + Native Lock | Remote Backend | Guarda el `.tfstate` en remoto con `use_lockfile = true`, sin tablas extra en DynamoDB. |
| Ubuntu 24.04 LTS | Sistema Operativo | Ligero y estable para ejecutar Docker. |
| Dynamic Blocks | Refactorización HCL | Genera reglas de ingress en los Security Groups desde listas de puertos. |
| IAM Instance Profiles | Seguridad | Acceso a DynamoDB y SSM con credenciales temporales (STS), sin llaves en código. |
| AWS Systems Manager (SSM) | Acceso y despliegue remoto | Sesiones y comandos sin SSH ni puertos abiertos. |
| Docker & Docker Compose | Runtime de contenedores | Instalado automáticamente por `user_data`. |
| Jenkins | CI/CD | Construye, prueba, publica la imagen y dispara el despliegue. |
| Docker Hub | Registry de imágenes | Almacena las imágenes que las instancias descargan al desplegar. |

---

## Qué Problema Resolvemos

En entornos de aprendizaje tradicionales es común configurar recursos manualmente en la consola de AWS. Esto genera:

- **"Snowflake Servers":** Servidores configurados a mano imposibles de recrear de forma exacta.
- **Costos Fantasma:** Olvidar borrar recursos genera cobros imprevistos.
- **Falta de Aislamiento:** Usar el mismo Security Group para todo compromete la seguridad.
- **Despliegues manuales:** Entrar por SSH a copiar y ejecutar comandos en cada release.

### Solución Implementada

- **Toda la infraestructura se define en código** con un solo `terraform apply`.
- **Destrucción total controlada** con `terraform destroy`.
- **Despliegues repetibles:** un script estándar (`deploy.sh`) en cada instancia y un pipeline que lo invoca por SSM.

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
    │   │   ├── main.tf             # Instancias EC2, IAM Roles (Dynamo, SSM, Jenkins) y Storage
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   │
    │   └── dynamodb/               # Tabla de persistencia para Telemetría
    │       ├── main.tf
    │       ├── variables.tf
    │       └── outputs.tf
    │
    └── scripts/
        └── init-docker.sh          # user_data: instala Docker y crea /opt/app/deploy.sh
```

---

## Guía de Despliegue Paso a Paso

### Prerrequisitos

- AWS CLI configurado (`aws configure`).
- Terraform v1.10.0 o superior.
- **Session Manager Plugin** instalado en tu máquina (necesario para `aws ssm start-session`).
- Cuenta de Docker Hub con un Access Token (para que Jenkins publique imágenes).

### Paso 1: Inicializar el Bootstrap (Estado Remoto)

```bash
cd bootstrap
terraform init
terraform apply
```

Toma nota del nombre del bucket S3 generado en los outputs.

### Paso 2: Configurar el backend

```bash
cd ../infrastructure
```

Crea o edita `backend.tfvars`:

```hcl
bucket       = "TU_BUCKET_NAME_GENERADO"
key          = "dev/infrastructure/terraform.tfstate"
region       = "us-east-1"
use_lockfile = true
encrypt      = true
```

```bash
terraform init -reconfigure -backend-config="backend.tfvars"
```

### Paso 3: Planificar y Aplicar

```bash
terraform plan
terraform apply
```

> **PowerShell:** los argumentos con puntos deben ir entre comillas, por ejemplo
> `terraform destroy -target="module.ec2.aws_instance.jenkins"`. Sin comillas, PowerShell corta el valor y Terraform muestra `Invalid target "module"`.

### Paso 4: Verificar que `user_data` terminó bien

Espera 2 o 3 minutos tras el `apply` y entra por SSM (ver siguiente sección):

```bash
cloud-init status --long        # debe decir: status: done, errors: []
sudo docker --version
sudo docker compose version
ls /opt/app                     # debe existir deploy.sh
```

> `status: done` indica que cloud-init terminó, no que el script haya salido bien. Por eso el `user_data` usa `set -euxo pipefail` y se confirma con `docker --version`. Si algo falló, el detalle está en `/var/log/cloud-init-output.log`.

---

## Acceso a las Instancias por SSM (sin SSH)

### Requisitos

1. Cada instancia tiene un **Instance Profile** con la política administrada `AmazonSSMManagedInstanceCore`.
2. **Salida a internet por 443** (Security Group con egress `443` hacia `0.0.0.0/0`) hacia los endpoints `ssm`, `ssmmessages` y `ec2messages`. En subred privada se necesita NAT Gateway o VPC Endpoints.
3. El SSM Agent viene preinstalado en las AMIs de Ubuntu de AWS.
4. Si la instancia **no aparece** en *Systems Manager → Fleet Manager*, revisa los puntos 1 y 2.

### Roles IAM

| Rol | Instancias | Permisos |
|---|---|---|
| `ec2_dynamo_role` | telemetry | `AmazonSSMManagedInstanceCore` + política de DynamoDB |
| `ec2_ssm_role` | account, database | `AmazonSSMManagedInstanceCore` |
| `jenkins_role` | jenkins | `AmazonSSMManagedInstanceCore` + `ssm:SendCommand` (sobre account, telemetry y el documento `AWS-RunShellScript`) + `ssm:GetCommandInvocation` |

### Metadata de la instancia (hop limit)

Las aplicaciones y el AWS CLI que corren **dentro de contenedores** obtienen las credenciales del rol desde el servicio de metadata. Con el valor por defecto (`hop limit = 1`) el contenedor no llega y falla con un error de credenciales. Por eso las instancias que corren contenedores con rol necesitan:

```hcl
metadata_options {
  http_endpoint               = "enabled"
  http_tokens                 = "required"
  http_put_response_hop_limit = 2
}
```

### Comandos útiles

```bash
# Shell interactiva en la instancia
aws ssm start-session --target i-xxxxxxxxxxxxxxxxx

# Túnel a la interfaz de Jenkins (abre http://localhost:8090)
aws ssm start-session --target i-JENKINS \
  --document-name AWS-StartPortForwardingSession \
  --parameters portNumber=8080,localPortNumber=8090

# Túnel a PostgreSQL para DBeaver / psql (localhost:5433)
aws ssm start-session --target i-DATABASE \
  --document-name AWS-StartPortForwardingSession \
  --parameters portNumber=5432,localPortNumber=5433
```

Con los túneles ya no es necesario abrir `8080`, `5432` ni `6379` al público (salvo el `8080` de Jenkins si usas webhooks de GitHub).

---

## Qué es Automático y Qué es Manual

| Qué | Cómo | Cuándo |
|---|---|---|
| VPC, subred, Security Groups, IAM, EC2, DynamoDB | Terraform (`apply`) | Una vez |
| Docker + Compose instalados | `user_data` (`init-docker.sh`) | Al primer arranque de cada instancia |
| Script `/opt/app/deploy.sh` | `user_data` (`init-docker.sh`) | Al primer arranque de cada instancia |
| Archivos `.env` de cada servicio | **Manual**, por SSM | Una vez por instancia |
| `docker-compose.yml` + `.env` de la base de datos | **Manual**, por SSM | Una vez |
| Jenkins en Docker (imagen propia con AWS CLI) | **Manual**, por SSM | Una vez |
| Plugins, credencial `docker-hub`, pipelines, variables globales | **Manual**, en la UI de Jenkins | Una vez |
| Build, push de imagen y despliegue de cada release | Pipeline de Jenkins | Cada push |

> **Importante:** `user_data` solo corre en el **primer arranque**. Cambiarlo en Terraform no vuelve a ejecutarlo en instancias existentes. Para esas, aplica los cambios a mano por SSM.

> **No pongas secretos en `user_data`:** queda guardado en el state de Terraform y es legible desde el metadata de la instancia. Los `.env` con contraseñas se crean a mano por SSM (o se leen de Parameter Store / Secrets Manager).

---

## `init-docker.sh` (user_data)

```bash
#!/bin/bash
set -euxo pipefail

apt-get update -y
apt-get install -y ca-certificates curl gnupg git
install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

usermod -aG docker ubuntu
systemctl enable --now docker

mkdir -p /opt/app
cat > /opt/app/deploy.sh <<'EOF'
#!/bin/bash
# Uso: deploy.sh <imagen:tag> <nombre> [args extra de docker run, ej: -p 8080:8080]
set -euo pipefail
IMAGE=$1
NAME=$2
shift 2
ENV_FILE=/opt/app/${NAME}.env

PREV=$(docker inspect -f '{{.Config.Image}}' "$NAME" 2>/dev/null || true)

docker pull "$IMAGE"
docker rm -f "$NAME" 2>/dev/null || true
docker run -d --name "$NAME" --restart unless-stopped --env-file "$ENV_FILE" "$@" "$IMAGE"

sleep 20
if [ "$(docker inspect -f '{{.State.Running}}' "$NAME")" != "true" ]; then
  echo "El contenedor no arrancó"
  if [ -n "$PREV" ]; then
    docker rm -f "$NAME" || true
    docker run -d --name "$NAME" --restart unless-stopped --env-file "$ENV_FILE" "$@" "$PREV"
    echo "Rollback a $PREV"
  fi
  exit 1
fi
EOF
chmod +x /opt/app/deploy.sh
```

> **Cuidado con el repositorio de Docker:** la línea `echo "deb ..."` debe ir en **una sola línea**. Si se parte con `\` y líneas en blanco, bash interpreta el texto como un comando, `docker.list` queda vacío y `apt` responde `E: Package 'docker-ce' has no installation candidate`.

---

## `deploy.sh`: cómo funciona

`deploy.sh` es el "actualizador" genérico de cada instancia. No instala nada: recibe una imagen y la deja corriendo.

```text
deploy.sh <imagen:tag> <nombre> [args de docker run...]
```

| Parámetro | Significado | Ejemplo |
|---|---|---|
| `imagen:tag` | Imagen de Docker Hub a desplegar | `juanb28/account-transaction-service:42` |
| `nombre` | Nombre del contenedor **y** del archivo env (`/opt/app/<nombre>.env`) | `account` |
| `args extra` | Se pasan tal cual a `docker run` (puertos, volúmenes, etc.) | `-p 8080:8080` |

**Qué hace, paso a paso:**

1. Guarda la imagen que corre actualmente (`PREV`), si existe, para poder volver a ella.
2. `docker pull` de la imagen nueva.
3. Elimina el contenedor anterior (`docker rm -f`).
4. Arranca el contenedor nuevo con `--env-file /opt/app/<nombre>.env` y `--restart unless-stopped`.
5. Espera 20 segundos y comprueba que siga corriendo. Si no, **hace rollback** a `PREV` y termina con error (el pipeline queda en rojo).

El primer despliegue también funciona: si el contenedor no existe, `PREV` queda vacío y simplemente lo crea (sin rollback posible).

### Ejemplos

```bash
# Telemetry
sudo /opt/app/deploy.sh juanb28/event-telemetry-service:latest telemetry -p 8081:8081 -p 9090:9090

# Account
sudo /opt/app/deploy.sh juanb28/account-transaction-service:latest account -p 8080:8080

# Ver logs
sudo docker logs account --tail 50

# Desde tu máquina, sin entrar a la instancia
aws ssm send-command \
  --instance-ids i-XXXXXXXX \
  --document-name AWS-RunShellScript \
  --parameters 'commands=["/opt/app/deploy.sh juanb28/event-telemetry-service:latest telemetry -p 8081:8081 -p 9090:9090"]'
```

> En despliegues reales usa el tag del build o del commit, no `latest`: así sabes qué versión corre y puedes volver a la anterior.

---

## Archivos `.env` por instancia (manual)

Las instancias están en la misma subred, así que se comunican por **IP privada** (`10.0.1.x`). Los nombres de servicio del `docker-compose` local (`postgres`, `redis`, `telemetry-service`) **no existen** en AWS. Reemplaza los valores entre `<...>` por las IPs privadas reales (`terraform output` o la consola de EC2).

Entra a cada instancia con `aws ssm start-session` y crea el archivo. Si el pegado multilínea falla en la terminal de SSM, usa `sudo -i` y pega por partes, o `nano`.

### Instancia `account` → `/opt/app/account.env`

```bash
sudo tee /opt/app/account.env > /dev/null <<'EOF'
SERVER_PORT_ACCOUNT=8080
POSTGRES_HOST=<IP_PRIVADA_DATABASE>
POSTGRES_PORT=5432
POSTGRES_DB=account_db
POSTGRES_USER=postgres
POSTGRES_PASSWORD=<TU_PASSWORD>
REDIS_HOST=<IP_PRIVADA_DATABASE>
REDIS_PORT=6379
TELEMETRY_GRPC_HOST=<IP_PRIVADA_TELEMETRY>
TELEMETRY_GRPC_PORT=9090
EOF
sudo chmod 600 /opt/app/account.env
```

### Instancia `telemetry` → `/opt/app/telemetry.env`

```bash
sudo tee /opt/app/telemetry.env > /dev/null <<'EOF'
SERVER_PORT_TELEMETRY=8081
GRPC_PORT=9090
AWS_REGION=us-east-1
DYNAMODB_TABLE_NAME=<NOMBRE_TABLA_DYNAMODB>
EOF
sudo chmod 600 /opt/app/telemetry.env
```

**Qué NO va en el `.env` de AWS:** `AWS_ENDPOINT_URL`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` ni `LOCALSTACK_AUTH_TOKEN`. Esas variables solo sirven para LocalStack. En AWS la aplicación usa el rol de la instancia.

Reglas de formato de `--env-file`: `CLAVE=valor`, sin comillas, sin `export` y sin espacios alrededor del `=`.

### Instancia `database` → Docker Compose

Aquí no se usa `deploy.sh`: corren Postgres y Redis con Compose.

```bash
sudo -i
mkdir -p /opt/app && cd /opt/app

cat > .env <<'EOF'
POSTGRES_DB=account_db
POSTGRES_USER=postgres
POSTGRES_PASSWORD=<TU_PASSWORD>
POSTGRES_PORT=5432
REDIS_PORT=6379
EOF
chmod 600 .env
```

```bash
cat > docker-compose.yml <<'EOF'
services:
  postgres:
    image: postgres:16-alpine
    container_name: postgres-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "${POSTGRES_PORT}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: redis-cache
    restart: unless-stopped
    ports:
      - "${REDIS_PORT}:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
EOF

docker compose config     # valida sintaxis y variables
docker compose up -d
docker ps                 # ambos deben aparecer healthy
```

Los valores de `POSTGRES_DB`, `POSTGRES_USER` y `POSTGRES_PASSWORD` deben ser **idénticos** a los de `account.env`.

---

## Orden de Arranque

1. **database:** `docker compose up -d` y comprobar `healthy`.
2. **telemetry:** `deploy.sh` con su imagen.
3. **account:** `deploy.sh` con su imagen (se conecta a Postgres, Redis y telemetry al arrancar).

---

## Jenkins (CI/CD)

### Instalación en la instancia

La imagen de Jenkins necesita Docker CLI y **AWS CLI** (para ejecutar `aws ssm send-command` desde el pipeline). Constrúyela en tu máquina, publícala en Docker Hub y descárgala en la instancia:

```bash
docker buildx build --platform linux/amd64 -t <usuario>/jenkins-custom:1 --push ./jenkins
```

En la instancia (`/opt/jenkins/docker-compose.yml`):

```yaml
services:
  jenkins:
    image: <usuario>/jenkins-custom:1
    container_name: jenkins
    restart: unless-stopped
    user: root
    privileged: true
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock

volumes:
  jenkins_home:
```

```bash
docker compose up -d
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
docker exec jenkins aws sts get-caller-identity     # debe mostrar el rol de Jenkins
```

### Configuración en la UI de Jenkins (manual)

| Qué | Dónde |
|---|---|
| Plugins: `git`, `workflow-aggregator`, `credentials-binding`, `junit`, `timestamper` (+ `github`, `slack`, `email-ext` según uso) | Manage Jenkins → Plugins |
| Credencial `docker-hub` (usuario + Access Token) | Manage Jenkins → Credentials |
| Variables globales: `AWS_DEFAULT_REGION`, `TELEMETRY_INSTANCE_ID`, `ACCOUNT_INSTANCE_ID`, `TELEMETRY_PORTS`, `ACCOUNT_PORTS` | Manage Jenkins → System → Global properties → Environment variables |
| Un pipeline por repo: *Pipeline script from SCM*, rama `*/dev`, Script Path `Jenkinsfile` | New Item → Pipeline |
| Disparador: *Poll SCM* (`H/2 * * * *`) o webhook de GitHub | Configure → Build Triggers |

Guardar los IDs de instancia como variables globales evita editar los Jenkinsfile cada vez que se recrea la infraestructura (el `i-0...` cambia).

### Flujo

```text
git push (dev) → Jenkins: Checkout → Build & Test → [Sonar] → Image Build
              → Push a Docker Hub → Deploy (aws ssm send-command → deploy.sh)
```

**Stage de despliegue** (ejemplo para telemetry):

```groovy
stage('Deploy') {
    when { expression { return params.RUN_DEPLOY } }
    steps {
        sh '''
            CMD_ID=$(aws ssm send-command \
              --instance-ids $TELEMETRY_INSTANCE_ID \
              --document-name AWS-RunShellScript \
              --parameters "commands=[\\"/opt/app/deploy.sh ${FULL_IMAGE}:${IMAGE_TAG} telemetry ${TELEMETRY_PORTS}\\"]" \
              --query Command.CommandId --output text)

            aws ssm wait command-executed \
              --command-id $CMD_ID --instance-id $TELEMETRY_INSTANCE_ID

            aws ssm get-command-invocation \
              --command-id $CMD_ID --instance-id $TELEMETRY_INSTANCE_ID \
              --query StandardOutputContent --output text
        '''
    }
}
```

Si `deploy.sh` falla, `aws ssm wait` devuelve error y el pipeline queda en rojo; el detalle está en *Systems Manager → Run Command*.

**Notas:**
- Los tests no deben depender de variables de entorno del servidor de CI. Usa valores por defecto en `application.yaml` (por ejemplo `${AWS_REGION:us-east-1}`); si no, Spring falla con `Could not resolve placeholder 'AWS_REGION'`.
- Los endpoints de LocalStack y las credenciales `test/test` deben aplicarse **solo si la variable existe**; en AWS el cliente debe usar el rol de la instancia (`DefaultCredentialsProvider`).
- `BUILD_NUMBER` es un contador propio de cada Jenkins; si se mezclan dos instancias de Jenkins, los tags no coinciden. Para trazabilidad es mejor usar el hash corto del commit.

---

## Solución de Problemas

| Síntoma | Causa probable | Solución |
|---|---|---|
| `sudo: docker: command not found` | `user_data` falló al instalar Docker (línea del repo partida) | Revisar `/var/log/cloud-init-output.log`; instalar con `curl -fsSL https://get.docker.com \| sudo sh` y corregir el script |
| La instancia no aparece en SSM | Sin perfil IAM, sin egress `443` o sin salida a internet | Verificar Instance Profile, Security Group y ruta a internet |
| `Connection refused: localhost:4566` en telemetry | La app usa por defecto el endpoint de LocalStack | Dejar vacíos los defaults de `endpoint-url` y credenciales en `application.yaml` |
| Error de credenciales en un contenedor dentro de EC2 | `hop limit = 1` | `http_put_response_hop_limit = 2` |
| `Error acquiring the state lock` (S3 `PreconditionFailed`) | Un `apply` anterior se interrumpió | Confirmar que no hay otro Terraform activo y ejecutar `terraform force-unlock <ID>` |
| `Invalid target "module"` en PowerShell | PowerShell corta el argumento en el punto | Poner el valor entre comillas: `-target="module.ec2.aws_instance.jenkins"` |
| Jenkins y SSM dejan de responder a la vez | Instancia sin memoria (OOM) con `t3.micro` | Reiniciar la instancia; usar `t3.medium` para Jenkins o añadir swap |
| `Unnecessary stubbings detected` en un test | Stub de Mockito que nunca se usa | Quitar el stub o verificar que no se llama (`verify(..., never())`) |
| `docker compose` o heredoc pegado se rompe en SSM | La terminal de SSM falla con bloques multilínea largos | Pegar por partes o usar `nano` |

---

## Tamaño de Instancias

`t3.micro` (1 GB de RAM) es suficiente para los microservicios, pero **no para Jenkins**: un build de Maven con Spring Boot lo deja sin memoria. Recomendado:

- **Jenkins:** `t3.medium` (4 GB) y disco de 25-30 GB (imágenes Docker, caché de Maven). Con Sonar, 4 GB como mínimo adicional.
- **Resto de instancias:** `t3.micro`.

Si no es posible, añade swap en Jenkins y limita la memoria (`JAVA_OPTS=-Xmx512m`, `MAVEN_OPTS=-Xmx384m`).

---

## Costos y Limpieza

```bash
# Apagar una instancia y conservar su disco (no se cobra cómputo)
aws ec2 stop-instances --instance-ids i-XXXXXXXX

# Volver a encenderla
aws ec2 start-instances --instance-ids i-XXXXXXXX

# Destruir todo
terraform destroy
```

- **Stop:** conserva el disco (y la configuración de Jenkins). Solo se cobra el EBS. La IP pública **cambia** al volver a encender (hay que actualizar webhooks).
- **Destroy:** elimina todo, incluidos los datos de Postgres y la configuración de Jenkins.
- Recursos que siguen cobrando aunque apagues las instancias: EBS, Elastic IPs asignadas, **NAT Gateway** y **VPC Endpoints de interfaz** (por hora).

---

## Este laboratorio NO es una arquitectura de producción

Para mantenerlo simple y dentro del Free Tier, este laboratorio toma atajos que **no se deben replicar en producción**:

### 1. Instancias en subred pública

Aquí todas las instancias tienen IP pública. En producción:

- Los servidores de aplicación y bases de datos van en **subredes privadas**, sin IP pública ni ruta directa desde internet.
- La única entrada desde internet es un **Application Load Balancer** (en subredes públicas) que reenvía a las aplicaciones.
- La salida a internet (descargar imágenes, actualizaciones, llegar a SSM) se hace por un **NAT Gateway**, o evitando internet con **VPC Endpoints** (`ssm`, `ssmmessages`, `ec2messages`, `ecr`, `s3`, `dynamodb`).

**Por qué:** una IP pública expone cada puerto abierto a escáneres automáticos, que encuentran bases de datos y Redis sin contraseña en cuestión de horas. En subred privada, esos servicios son inalcanzables desde fuera aunque un Security Group esté mal configurado.

> El NAT Gateway tiene costo por hora y por GB procesado, por eso no se usa en este laboratorio. Es parte del precio de una red segura.

### 2. Base de datos y caché en una EC2 con Docker

Postgres y Redis en un contenedor, sin backups ni alta disponibilidad. En producción se usan servicios administrados: **Amazon RDS** (backups automáticos, Multi-AZ, parches) y **ElastiCache**.

### 3. Secretos en archivos `.env`

Las contraseñas viven en texto plano en el disco de la instancia. En producción se usan **AWS Secrets Manager** o **SSM Parameter Store (SecureString)**, leídos por el rol de la instancia al arrancar.

### 4. Una instancia por servicio, sin escalado

Una sola instancia por servicio es un punto único de fallo. En producción: **ECS/Fargate o EKS** con múltiples réplicas, **Auto Scaling** y health checks gestionados por el balanceador.

### 5. Jenkins expuesto y con permisos amplios

Jenkins con el puerto abierto a internet es un blanco frecuente. En producción: sin acceso público (VPN, SSM port-forward o ALB con autenticación), HTTPS, SSO, agentes efímeros, y un rol IAM limitado a los servicios que despliega.

### 6. Tráfico sin cifrar y sin dominio

Los servicios responden por HTTP sobre IP. En producción: **HTTPS** con certificados de **ACM** en el balanceador, dominio en **Route 53** y, si aplica, **WAF** delante.

### 7. Security Groups abiertos

En el laboratorio algunos puertos se abren a `0.0.0.0/0`. En producción cada puerto se abre **solo al Security Group de quien lo consume** (por ejemplo, `5432` solo desde el SG de account; `9090` solo desde account hacia telemetry).

### 8. Despliegue sin versionado ni entornos separados

Se despliega por SSM con un script simple, sin estrategia de release. En producción: entornos separados (dev/staging/prod, idealmente en cuentas distintas), imágenes inmutables con tag por commit en **ECR**, despliegues *blue/green* o *rolling* con rollback automático, y políticas de aprobación para producción.

### 9. Observabilidad y auditoría mínimas

Solo hay `docker logs`. En producción: logs centralizados (**CloudWatch Logs**), métricas y alarmas, trazas, y auditoría con **CloudTrail**.

---

## Valor de Aprendizaje

Aunque la escala es pequeña, el laboratorio aborda patrones esenciales de proyectos reales:

- **Inyección de scripts mediante User Data:** aprovisionamiento automático desde el primer arranque.
- **Integración IAM + EC2:** acceso a servicios de AWS sin credenciales estáticas (Instance Profiles).
- **Acceso sin SSH con SSM:** sesiones, túneles y comandos remotos auditables.
- **CI/CD completo:** build, imagen, registry y despliegue remoto con rollback.
- **Nativo vs Deprecado en IaC:** bloqueo de estado con `use_lockfile` en S3.
- **Conciencia de qué mejorar:** entender por qué cada atajo del laboratorio no es válido en producción.