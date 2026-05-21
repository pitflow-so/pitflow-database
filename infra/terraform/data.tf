data "aws_secretmanager_secret" "pitflow" {
  name = var.secret_name
}

data "aws_secretsmanager_secret_version" "pitflow" {
  secret_id = data.aws_secretsmanager_secret.pitflow.id
}