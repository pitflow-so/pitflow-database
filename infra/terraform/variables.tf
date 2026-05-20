variable "secret_name" {
  description = "Secrets Manager secret read by the Lambda functions."
  type        = string
  default     = "pitflow/bootstrap"
}