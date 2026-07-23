output "postgres_host" {
  description = "Shared PostgreSQL RDS hostname."
  value       = aws_db_instance.postgres.address
}

output "postgres_port" {
  description = "Shared PostgreSQL RDS port."
  value       = aws_db_instance.postgres.port
}

output "postgres_instance_identifier" {
  description = "Current physical RDS identifier."
  value       = aws_db_instance.postgres.identifier
}

output "postgres_database_names" {
  description = "Logical PostgreSQL database names by microservice."
  value       = local.database_names
  sensitive   = true
}

output "orchestrator_table_name" {
  description = "DynamoDB table name for the SAGA orchestrator."
  value       = aws_dynamodb_table.orchestrator.name
}

output "orchestrator_table_arn" {
  description = "DynamoDB table ARN for least-privilege runtime policies."
  value       = aws_dynamodb_table.orchestrator.arn
}

output "orchestrator_table_region" {
  description = "AWS region of the DynamoDB table."
  value       = var.aws_region
}
