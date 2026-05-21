locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.pitflow.secret_string)
}