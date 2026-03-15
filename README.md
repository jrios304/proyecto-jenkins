# proyecto-jenkins — Despliegue Escalable con Kubernetes

API REST en Python (FastAPI) desplegada en Kubernetes con escalabilidad automática (HPA), pipeline CI/CD con Jenkins e infraestructura como código con Terraform.

**Integrantes:** Jefferson Ríos · Brayan Díaz

---

## Arquitectura

![Diagrama de arquitectura](docs/arquitectura.svg)

---

## Tecnologías

| Herramienta | Rol |
|---|---|
| FastAPI + Python 3.11 | API REST |
| Docker | Contenedorización |
| Docker Hub | Registro de imágenes |
| Jenkins | Pipeline CI/CD automatizado |
| Kubernetes (Minikube) | Orquestación del cluster |
| HPA | Escalabilidad automática (2–10 pods) |
| Terraform | Infraestructura como código |

---

## Estructura del repositorio

```
proyecto-jenkins/
├── app/
│   └── app.py                 # API FastAPI
├── tests/                     # Pruebas automatizadas
├── kubernetes/
│   ├── deployment.yaml        # Despliegue de la app
│   ├── service.yaml           # Exposición del servicio
│   └── hpa.yaml               # Escalabilidad automática
├── terraform/
│   ├── main.tf                # Genera configuración IaC
│   ├── variables.tf           # Variables: app, imagen, réplicas, puertos
│   ├── outputs.tf             # Outputs: nombre, entorno, imagen, réplicas
│   └── terraform.tfvars       # Valores de las variables
├── docs/
│   └── arquitectura.svg       # Diagrama de arquitectura
├── Dockerfile
├── Jenkinsfile                # Pipeline CI/CD
└── requirements.txt
```

---

## Configuración previa

Antes de ejecutar, reemplaza `tu-usuario` con tu nombre de usuario de Docker Hub en:

- `kubernetes/deployment.yaml` → campo `image:`
- `terraform/terraform.tfvars` → campo `image_name`

---

## Pipeline CI/CD (Jenkins)

El `Jenkinsfile` define 6 etapas que se ejecutan automáticamente en cada push a la rama `main` mediante webhook de GitHub.

| Etapa | Comando | Descripción |
|---|---|---|
| **Checkout** | `checkout scm` | Clona el código fuente desde GitHub |
| **Build** | `pip install -r requirements.txt` | Instala dependencias de Python |
| **Test** | `pytest tests/ --cov=app` | Ejecuta pruebas con cobertura de código |
| **Terraform Validate** | `terraform init && validate` | Valida la configuración IaC |
| **Kubernetes Validation** | `type kubernetes/*.yaml` | Verifica que los manifiestos existen |
| **Deploy Simulation** | `echo` | Simula el despliegue mostrando info por consola |

### Ejecutar Jenkins

```bash
# Iniciar Jenkins (requiere Java)
java -jar jenkins.war

# Acceder a la interfaz web
# http://localhost:8080
```

### Trigger automático

Cada `git push` a `main` dispara el pipeline automáticamente a través del webhook configurado en GitHub → Jenkins.

---

## Despliegue local (Minikube)

### 1. Requisitos

```bash
docker --version     # Docker 20+
kubectl version      # kubectl 1.25+
minikube version     # Minikube 1.30+
```

### 2. Construir y publicar la imagen

```bash
docker build -t tu-usuario/test-api:latest .
docker push tu-usuario/test-api:latest
```

### 3. Iniciar Minikube y habilitar métricas

```bash
minikube start --cpus=2 --memory=4096
minikube addons enable metrics-server
```

### 4. Desplegar en Kubernetes

```bash
kubectl apply -f kubernetes/
kubectl get pods       # verificar pods Running
kubectl get services   # verificar servicio
kubectl get hpa        # verificar autoscaler
```

### 5. Acceder a la API

```bash
# Abrir túnel (mantener esta terminal abierta)
minikube service test-api-service

# En otra terminal
curl http://127.0.0.1:<PUERTO>/
curl http://127.0.0.1:<PUERTO>/health
curl http://127.0.0.1:<PUERTO>/tasks

# Swagger UI — abrir en el navegador
# http://127.0.0.1:<PUERTO>/docs
```

---

## Infraestructura como código (Terraform)

Terraform gestiona la configuración del despliegue de forma declarativa y versionada.

### Archivos

| Archivo | Descripción |
|---|---|
| `variables.tf` | Variables: nombre de app, entorno, imagen, réplicas y puertos |
| `main.tf` | Genera el archivo de configuración del despliegue |
| `outputs.tf` | Expone los valores clave tras aplicar la configuración |
| `terraform.tfvars` | Valores concretos de las variables para este proyecto |

### Ejecutar Terraform

```bash
cd terraform/

terraform init     # inicializar proveedores
terraform plan     # previsualizar cambios
terraform apply    # aplicar configuración
terraform output   # ver outputs
```

### Outputs disponibles

```
application_name       = "proyecto-jenkins"
deployment_environment = "produccion"
deployment_image       = "tu-usuario/test-api:latest"
desired_replicas       = 3
```

---

## Endpoints de la API

| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/` | Info de la app |
| GET | `/health` | Health check (usado por K8s) |
| GET | `/tasks` | Listar tareas |
| GET | `/tasks/{id}` | Obtener tarea por ID |
| POST | `/tasks` | Crear tarea |
| PUT | `/tasks/{id}` | Actualizar tarea |
| DELETE | `/tasks/{id}` | Eliminar tarea |

---

## Prueba de escalabilidad (HPA)

```bash
# Generar carga
kubectl run load-generator --image=busybox:1.28 --restart=Never \
  -- /bin/sh -c "while true; do wget -q -O- http://test-api-service:80/tasks; done"

# Observar escalado automático (en otra terminal)
kubectl get hpa -w
```

**Comportamiento observado:**

```
cpu: 2%/50%    →  2 pods  (reposo)
cpu: 148%/50%  →  4 pods  (HPA detecta sobrecarga)
cpu: 148%/50%  →  6 pods  (continúa escalando)
cpu: 66%/50%   →  8 pods  (más pods absorben la carga)
cpu: 1%/50%    →  2 pods  (scale down tras periodo de enfriamiento)
```

---

## Prueba de resiliencia

```bash
# Eliminar un pod manualmente
kubectl delete pod <nombre-del-pod>

# Verificar que se recrea automáticamente
kubectl get pods -w
```

Kubernetes recrea el pod eliminado en menos de 15 segundos sin intervención manual.

---

## Reflexión final

**¿Cómo mejorarías el uso de recursos?**
Ajustando los límites de CPU/memoria en el `deployment.yaml` según el perfil real de la aplicación, y configurando el HPA con métricas personalizadas (peticiones por segundo) además de CPU.

**¿Qué ventajas tiene IaC con Terraform?**
Permite reproducir la configuración del despliegue en cualquier entorno con un solo comando, versionarla en Git y hacer rollback si algo falla, eliminando la configuración manual y sus errores asociados.

**¿Cómo aplicarías esto en producción?**
Usando un cluster multi-zona para alta disponibilidad, integrando el pipeline Jenkins con `kubectl apply` real en lugar de simulación, y agregando monitoreo con Prometheus y Grafana para visualizar el comportamiento del HPA en tiempo real.
