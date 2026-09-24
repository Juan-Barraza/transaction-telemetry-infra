terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.66.0"
    }
  }
  backend "s3" {}
}   


provider "aws" {
  region = var.aws_region
}



module "vpc" {
    source = "./modules/vpc"
    project_name = var.project_name
    environment = var.environment
    cidr_block_vpc = var.cidr_block_vpc
    public_subnet_cidr = var.public_subnet_cidr
    jenkins_ingress_ports = var.jenkins_ingress_ports
    telemetry_ingress_ports = var.telemetry_ingress_ports
    account_ingress_ports = var.account_ingress_ports
    db_ingress_ports = var.db_ingress_ports
}

