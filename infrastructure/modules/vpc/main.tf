resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block_vpc
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc-${var.environment}"
    Environment = var.environment
  }
}


resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.zone

  tags = {
    Name        = "${var.project_name}-public-subnet-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw-${var.environment}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt-${var.environment}"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


resource "aws_security_group" "jenkins_sg" {
  name        = "${var.project_name}-jenkins-sg-${var.environment}"
  description = "Acceso a Jenkins"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.jenkins_ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-jenkins-sg-${var.environment}"
  }
}

resource "aws_security_group" "telemetry_sg" {
  name        = "${var.project_name}-telemetry-sg-${var.environment}"
  description = "Acceso a Telemetry Service"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.telemetry_ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-telemetry-sg-${var.environment}"
  }
}

resource "aws_security_group" "account_sg" {
  name        = "${var.project_name}-account-sg-${var.environment}"
  description = "Acceso a Account Service"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.account_ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-account-sg-${var.environment}"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg-${var.environment}"
  description = "Acceso a Base de Datos (PostgreSQL / Redis)"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.db_ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = [var.cidr_block_vpc]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-sg-${var.environment}"
  }
}