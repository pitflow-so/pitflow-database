locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.pitflow.secret_string)

  rds_master_username = local.db_credentials.PITFLOW_OPERATION_DB_USERNAME
  rds_master_password = local.db_credentials.PITFLOW_OPERATION_DB_PASSWORD

  database_names = {
    operation = local.db_credentials.PITFLOW_OPERATION_DB_NAME
    inventory = local.db_credentials.PITFLOW_INVENTORY_DB_NAME
    registry  = local.db_credentials.PITFLOW_REGISTRY_DB_NAME
    payment   = local.db_credentials.PITFLOW_PAYMENT_DB_NAME
  }
}
