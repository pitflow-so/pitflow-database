resource "aws_default_vpc" "default" {}

resource "aws_security_group" "rds_sg" {
  name        = "pitflow-rds-sg"
  description = "Acesso ao Postgres do Pitflow"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Database instance
resource "aws_db_instance" "postegres" {
  identifier           = "pitflow-db"
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "16"
  instance_class       = "db.t3.micro"
  db_name              = local.db_credentials.DB_NAME
  username             = local.db_credentials.DB_USER
  password             = local.db_credentials.DB_PASSWORD
  parameter_group_name = "default.postgres16"

  publicly_accessible    = true # Deixei público para testes com dbeaver
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  deletion_protection    = false
}

# Output já retornando sem a porta, exemplo: "pitflow-db.abcdefghij.us-east-1.rds.amazonaws.com"
output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}
