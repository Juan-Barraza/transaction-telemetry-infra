variable "aws_region" {
  description = "Región de AWS donde se crearán los recursos del backend"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}