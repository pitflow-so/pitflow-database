resource "aws_default_vpc" "default" {}

resource "aws_security_group" "rds_sg" {
  name        = "pitflow-rds-sg"
  description = "Acesso ao Postgres do Pitflow"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_postgres_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Database instance
resource "aws_db_instance" "postgres" {
  identifier           = var.rds_identifier
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "16"
  instance_class       = "db.t3.micro"
  username             = local.rds_master_username
  password             = local.rds_master_password
  parameter_group_name = "default.postgres16"

  publicly_accessible    = true # Deixei público para testes com dbeaver
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  deletion_protection    = false
}
