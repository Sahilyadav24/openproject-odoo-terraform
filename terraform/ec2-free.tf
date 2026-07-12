data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = var.key_pair_name
  public_key = file(var.public_key_path)
}

resource "aws_iam_role" "ec2_role" {
  name = "openproject-odoo-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "openproject-odoo-ec2-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "openproject-odoo-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "main" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = aws_key_pair.deployer.key_name

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  monitoring            = true

  user_data = templatefile("${path.module}/../scripts/user_data.sh.tpl", {
    db_host       = aws_db_instance.main.address
    db_secret_arn = aws_secretsmanager_secret.db_password.arn
    aws_region    = var.aws_region
  })

  root_block_device {
    volume_type           = "gp2"
    volume_size            = 30
    delete_on_termination  = true
    encrypted              = true
  }

  tags = {
    Name = "openproject-odoo-server"
  }
}

resource "aws_eip" "main" {
  instance = aws_instance.main.id
  domain   = "vpc"

  tags = {
    Name = "openproject-odoo-eip"
  }
}