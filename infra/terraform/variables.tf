variable "secret_name" {
  description = "Name of the Secrets Manager secret maintained by the secrets repository."
  type        = string
  default     = "pitflow/bootstrap"
}

variable "aws_region" {
  description = "AWS region where the database infrastructure is deployed."
  type        = string
  default     = "us-east-1"
}

variable "rds_identifier" {
  description = "Physical identifier of the shared PostgreSQL RDS instance."
  type        = string
  default     = "pitflow-operation-db"
}

variable "allowed_postgres_cidr_blocks" {
  description = "CIDR blocks allowed to connect to PostgreSQL. The current public rule is preserved by default to avoid an unplanned outage; restrict it after network discovery."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "orchestrator_table_name" {
  description = "DynamoDB table used by the SAGA orchestrator."
  type        = string
  default     = "pitflow-orchestrator"
}

variable "tags" {
  description = "Tags applied to managed AWS resources."
  type        = map(string)
  default = {
    Project     = "pitflow"
    ManagedBy   = "terraform"
    Environment = "lab"
  }
}
