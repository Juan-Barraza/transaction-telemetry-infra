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

module "ec2" {
    source = "./modules/ec2"
    project_name = var.project_name
    environment = var.environment
    subnet_id = module.vpc.public_subnet_id
    ami_id =  var.ami_id
    instance_type = var.instance_type
    key_name = data.aws_key_pair.key_pair.key_name
    user_data_path = "${path.module}/scripts/init-docker.sh"
    dynamodb_table_arn = module.dynamodb.table_arn
    jenkins_security_group_id = module.vpc.jenkins_security_group_id
    telemetry_security_group_id = module.vpc.telemetry_security_group_id
    account_security_group_id = module.vpc.account_security_group_id
    db_security_group_id = module.vpc.db_security_group_id
}