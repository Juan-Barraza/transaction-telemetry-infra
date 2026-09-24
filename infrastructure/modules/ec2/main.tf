resource "aws_iam_role" "ec2_dynamo_role" {
  name = "${var.project_name}-ec2-dynamo-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "dynamo_access_policy" {
  name        = "${var.project_name}-dynamo-policy-${var.environment}"
  description = "Permisos de acceso a la tabla de telemetría en DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ]
      Resource = [
        var.dynamodb_table_arn,
        "${var.dynamodb_table_arn}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_dynamo_policy" {
  role       = aws_iam_role.ec2_dynamo_role.name
  policy_arn = aws_iam_policy.dynamo_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile-${var.environment}"
  role = aws_iam_role.ec2_dynamo_role.name
}

resource "aws_instance" "jenkins" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.jenkins_security_group_id]
  user_data              = file(var.user_data_path)

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = {
    Name        = "${var.project_name}-jenkins-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_instance" "telemetry" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.telemetry_security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  user_data              = file(var.user_data_path)

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = {
    Name        = "${var.project_name}-telemetry-service-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_instance" "account" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.account_security_group_id]
  user_data              = file(var.user_data_path)

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = {
    Name        = "${var.project_name}-account-service-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_instance" "database" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.db_security_group_id]
  user_data              = file(var.user_data_path)

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = {
    Name        = "${var.project_name}-database-${var.environment}"
    Environment = var.environment
  }
}