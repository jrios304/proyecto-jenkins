variable "app_name" {
  description = "Nombre de la aplicacion"
  type        = string
  default     = "proyecto-jenkins"
}

variable "environment" {
  description = "Entorno de despliegue"
  type        = string
  default     = "produccion"
}

variable "image_name" {
  description = "Nombre de la imagen del contenedor"
  type        = string
  default     = "jrios304/test-api:latest"
}

variable "replicas" {
  description = "Numero de replicas"
  type        = number
  default     = 3
}

variable "service_port" {
  description = "Puerto expuesto por el servicio"
  type        = number
  default     = 80
}

variable "container_port" {
  description = "Puerto interno del contenedor"
  type        = number
  default     = 8000
}