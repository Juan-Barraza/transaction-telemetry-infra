output "s3_bucket_name" {
  description = "Nombre del bucket S3 creado para registrar en el backend del proyecto principal"
  value       = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB creada para el bloqueo de estado"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "aws_region" {
  description = "Región de AWS configurada"
  value       = var.aws_region
}