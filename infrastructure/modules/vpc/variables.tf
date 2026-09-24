variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
}

variable "cidr_block_vpc" {
  description = "Bloque CIDR asignado a la VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "Bloque CIDR para la subred pública"
  type        = string
}

variable "jenkins_ingress_ports" {
  description = "Lista de puertos de entrada para Jenkins"
  type        = list(number)
}

variable "telemetry_ingress_ports" {
  description = "Lista de puertos de entrada para Telemetry Service"
  type        = list(number)
}

variable "account_ingress_ports" {
  description = "Lista de puertos de entrada para Account Service"
  type        = list(number)
}

variable "db_ingress_ports" {
  description = "Lista de puertos de entrada para Base de Datos"
  type        = list(number)
}