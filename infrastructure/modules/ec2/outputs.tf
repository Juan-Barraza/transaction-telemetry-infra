output "jenkins_public_ip" {
  description = "IP pública del servidor Jenkins"
  value       = aws_instance.jenkins.public_ip
}

output "telemetry_public_ip" {
  description = "IP pública del servicio Telemetry"
  value       = aws_instance.telemetry.public_ip
}

output "account_public_ip" {
  description = "IP pública del servicio Account"
  value       = aws_instance.account.public_ip
}

output "database_public_ip" {
  description = "IP pública de la instancia de Base de Datos"
  value       = aws_instance.database.public_ip
}