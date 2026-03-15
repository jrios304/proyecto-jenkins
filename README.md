# proyecto-jenkins — Despliegue Escalable con Kubernetes

API REST en Python (FastAPI) desplegada en Kubernetes con escalabilidad automática (HPA), pipeline CI/CD con Jenkins e infraestructura como código con Terraform. El proyecto fue implementado en dos entornos: Minikube local y Google Kubernetes Engine (GKE).

**Integrantes:** Jefferson Ríos · Brayan Díaz

---

## Arquitectura

![Diagrama de arquitectura](docs/arquitectura.svg)

---

## Tecnologías

| Herramienta | Rol |
|---|---|
| FastAPI + Python 3.11 | API REST con CRUD de tareas |
| Docker + Docker Hub | Contenedorización y registro de imagen |
| Kubernetes (Minikube) | Orquestación local |
| Google Cloud (GKE) | Orquestación en la nube |
| HPA | Escalabilidad automática 2–10 pods |
| Jenkins | Pipeline CI/CD de 6 etapas |
| Terraform | Infraestructura como código |

---

## Estructura del repositorio

```
proyecto-jenkins/
├── app/
│   └── app.py                 # API FastAPI
├── tests/                     # Pruebas automatizadas (14 tests, 100% coverage)
├── kubernetes/
│   ├── deployment.yaml        # Despliegue de la app (3 réplicas)
│   ├── service.yaml           # Exposición del servicio (LoadBalancer :80)
│   └── hpa.yaml               # Escalabilidad automática (2–10 pods)
├── terraform/
│   ├── main.tf                # Genera configuración IaC
│   ├── variables.tf           # Variables: app, imagen, réplicas, puertos
│   ├── outputs.tf             # Outputs: nombre, entorno, imagen, réplicas
│   └── terraform.tfvars       # Valores de las variables
├── docs/
│   └── arquitectura.svg       # Diagrama de arquitectura
├── Dockerfile
├── Jenkinsfile                # Pipeline CI/CD (6 etapas)
└── requirements.txt
```

---

## Configuración previa

Antes de ejecutar, reemplaza `tu-usuario` con tu nombre de usuario de Docker Hub en:

- `kubernetes/deployment.yaml` → campo `image:`
- `terraform/terraform.tfvars` → campo `image_name`

---

## Pipeline CI/CD (Jenkins)

El `Jenkinsfile` define 6 etapas que se ejecutan automáticamente en cada push a `main` mediante webhook de GitHub.

| Etapa | Comando | Resultado |
|---|---|---|
| **Checkout** | `checkout scm` | Clona código desde GitHub |
| **Build** | `pip install -r requirements.txt` | Instala dependencias |
| **Test** | `pytest tests/ --cov=app` | 14/14 PASSED, 100% coverage |
| **Terraform Validate** | `terraform init && validate` | Configuration is valid |
| **Kubernetes Validation** | `type kubernetes/*.yaml` | Manifiestos verificados |
| **Deploy Simulation** | `echo` | Build #6 — Finished: SUCCESS |

```bash
# Iniciar Jenkins
java -jar jenkins.war
# Acceder: http://localhost:8080
```

---

## Despliegue local (Minikube)

### Requisitos

```bash
docker --version     # Docker 20+
kubectl version      # kubectl 1.25+
minikube version     # Minikube 1.30+
```

### Comandos

```bash
# Construir y publicar imagen
docker build -t tu-usuario/test-api:latest .
docker push tu-usuario/test-api:latest

# Iniciar Minikube
minikube start --cpus=2 --memory=4096
minikube addons enable metrics-server

# Desplegar
kubectl apply -f kubernetes/
kubectl get pods
kubectl get services
kubectl get hpa

# Acceder a la API (mantener terminal abierta)
minikube service test-api-service
# Swagger UI: http://127.0.0.1:<PUERTO>/docs
```

---

## Despliegue en Google Cloud (GKE)

```bash
# Autenticar en Google Cloud
gcloud auth login
gcloud config set project TU_PROJECT_ID

# Obtener credenciales del cluster
gcloud container clusters get-credentials CLUSTER_NAME --region REGION

# Desplegar los mismos manifiestos
kubectl apply -f kubernetes/
kubectl get pods
kubectl get services
kubectl get hpa
```

---

## Infraestructura como código (Terraform)

```bash
cd terraform/
terraform init     # inicializar proveedores
terraform plan     # previsualizar cambios
terraform apply    # aplicar configuración
terraform output   # ver outputs
```

**Outputs:**
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
kubectl run load-generator --image=busybox:1.28 --restart=Never \
  -- /bin/sh -c "while true; do wget -q -O- http://test-api-service:80/tasks; done"

kubectl get hpa -w
```

**Comportamiento observado:**

```
cpu: 2%/50%    →  2 pods  (reposo)
cpu: 148%/50%  →  4 pods  (HPA detecta sobrecarga)
cpu: 148%/50%  →  6 pods  (continúa escalando)
cpu: 66%/50%   →  8 pods  (absorbe la carga)
cpu: 1%/50%    →  2 pods  (scale down tras enfriamiento)
```

---

## Prueba de resiliencia

```bash
kubectl delete pod <nombre-del-pod>
kubectl get pods -w
```

Kubernetes recrea el pod eliminado en menos de 15 segundos sin intervención manual. Validado en Minikube y en GKE.

---

## Reflexión final

**¿Cómo mejorarías el uso de recursos?**
Configurar el HPA con métricas personalizadas (peticiones por segundo) y usar autoscaling de nodos en GKE para aprovisionar recursos solo cuando sea necesario.

**¿Qué ventajas tiene IaC con Terraform?**
Reproducibilidad total con un solo comando, versionamiento en Git y portabilidad entre entornos — los mismos manifiestos funcionaron en Minikube y en GKE sin modificaciones.

**¿Cómo aplicarías esto en producción?**
Reemplazar Deploy Simulation por `helm upgrade --install` real en GKE multi-zona, con aprobación manual antes de producción, rollback automático si el health check falla, y monitoreo con Prometheus y Grafana.
