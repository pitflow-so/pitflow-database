terraform {
  backend "s3" {
    bucket = "tfstate-backend-pitflow-bootstrap"
    key    = "infra/terraform/database/terraform.tfstate"
    region = "us-east-1"
  }
}
