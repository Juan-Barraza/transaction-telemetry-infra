output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_id" {
  value = module.vpc.public_subnet_id
}

output "jenkins_security_group_id" {
  value = module.vpc.jenkins_security_group_id
}