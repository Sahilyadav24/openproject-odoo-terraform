resource "random_password" "db_password" {
  length  = 20
  special = false
}

resource "aws_db_subnet_group" "main" {
  name       = "openproject-odoo-db-subnet"
  subnet_ids = [aws_subnet.public.id, aws_subnet.public2.id]
  tags = {
    Name = "db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier              = "openproject-odoo-free"
  engine                  = "postgres"
  engine_version          = "15.18"
  instance_class          = var.db_instance_class
  allocated_storage       = var.allocated_storage
  storage_type            = "gp2"

  db_name                 = "openproject_odoo"
  username                = "dbadmin"
  password                = random_password.db_password.result

  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds.id]

  multi_az                = false
  storage_encrypted       = true
  backup_retention_period = 1
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  publicly_accessible       = false
  skip_final_snapshot       = false
  final_snapshot_identifier = "openproject-odoo-final-snapshot"

  tags = {
    Name = "openproject-odoo-postgres"
  }
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "openproject-odoo/db-password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}