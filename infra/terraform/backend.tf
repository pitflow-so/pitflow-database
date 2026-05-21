terraform {
  backend "s3" {
    bucket = "tfstate-backend-fiap-pitflow"
    key    = "infra/terraform/database/terraform.tfstate"
    region = "us-east-1"
  }
}
