variable "aws_region" {
  description = "Región de AWS"
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

variable "cidr_block_vpc" {
  type = string
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
variable "zone" {
  description = "Zona de disponibilidad"
  type        = string
}


variable "tags_dynamodb" {
  description = "tags para la tabla de DynamoDB"
  type        = list(string)
}

variable "hash_key" {
    description = "Clave hash para la tabla de DynamoDB"
    type        = string
}

variable "range_key" {
    description = "Clave de rango para la tabla de DynamoDB"
    type        = string
}
variable "billing_mode" {
    description = "Modo de facturación para la tabla de DynamoDB"
    type        = string
    default     = "PAY_PER_REQUEST"
}