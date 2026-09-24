output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}
output "public_subnet_id" { 
  description = "ID de la subred pública"
  value       = aws_subnet.public.id
}

output "jenkins_security_group_id" {
  description = "ID del grupo de seguridad de Jenkins"
  value       = aws_security_group.jenkins_sg.id
}

output "telemetry_security_group_id" {
  description = "ID del grupo de seguridad de Telemetry Service"
  value       = aws_security_group.telemetry_sg.id
}

output "account_security_group_id" {
  description = "ID del grupo de seguridad de Account Service"
  value       = aws_security_group.account_sg.id
}

output "db_security_group_id" {
  description = "ID del grupo de seguridad de Base de Datos"
  value       = aws_security_group.db_sg.id
}
