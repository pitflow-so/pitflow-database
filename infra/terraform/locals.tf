locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.pitflow.secret_string)

  # Legacy keys are intentionally preferred while the existing RDS instance is
  # migrated. Removing/changing the master username could force replacement.
  rds_master_database = try(local.db_credentials.DB_NAME, local.db_credentials.PITFLOW_OPERATION_DB_NAME)
  rds_master_username = try(local.db_credentials.DB_USERNAME, local.db_credentials.PITFLOW_OPERATION_DB_USERNAME)
  rds_master_password = try(local.db_credentials.DB_PASSWORD, local.db_credentials.PITFLOW_OPERATION_DB_PASSWORD)

  database_names = {
    operation = "pitflow-operation-db"
    inventory = "pitflow-inventory-db"
    registry  = "pitflow-registry-db"
    payment   = "pitflow-payment-db"
  }
}
