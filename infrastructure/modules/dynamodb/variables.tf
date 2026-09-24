variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}
variable "environment" {
  description = "AmbieFnte de despliegue"
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