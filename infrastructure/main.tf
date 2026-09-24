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
    zone = var.zone
    cidr_block_vpc = var.cidr_block_vpc
    public_subnet_cidr = var.public_subnet_cidr
    jenkins_ingress_ports = var.jenkins_ingress_ports
    telemetry_ingress_ports = var.telemetry_ingress_ports
    account_ingress_ports = var.account_ingress_ports
    db_ingress_ports = var.db_ingress_ports
}

module "dynamodb" {
    source = "./modules/dynamodb"
    project_name = var.project_name
    environment = var.environment
    tags_dynamodb = var.tags_dynamodb
    hash_key = var.hash_key
    range_key = var.range_key
    billing_mode = var.billing_mode
}