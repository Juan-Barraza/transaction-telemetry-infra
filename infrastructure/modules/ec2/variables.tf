variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
}

variable "subnet_id" {
  description = "ID de la subred donde se desplegarán las instancias"
  type        = string
}

variable "ami_id" {
  description = "ID de la AMI a utilizar para las instancias"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Nombre del Key Pair para acceso SSH (opcional)"
  type        = string
  default     = null
}

variable "user_data_path" {
  description = "Ruta del script de inicialización user_data"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN de la tabla de DynamoDB para asignación de permisos IAM"
  type        = string
}

variable "jenkins_security_group_id" {
  description = "ID del Security Group para Jenkins"
  type        = string
}

variable "telemetry_security_group_id" {
  description = "ID del Security Group para Telemetry Service"
  type        = string
}

variable "account_security_group_id" {
  description = "ID del Security Group para Account Service"
  type        = string
}

variable "db_security_group_id" {
  description = "ID del Security Group para la Base de Datos"
  type        = string
}