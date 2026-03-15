terraform {
  required_version = ">= 1.5.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "local" {}

resource "local_file" "deployment_config" {
  filename = "${path.module}/generated_deployment_info.txt"

  content = <<EOT
Aplicacion: ${var.app_name}
Entorno: ${var.environment}
Imagen: ${var.image_name}
Replicas deseadas: ${var.replicas}
Puerto servicio: ${var.service_port}
Puerto contenedor: ${var.container_port}
EOT
}