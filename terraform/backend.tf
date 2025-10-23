# terraform/backend.tf

terraform {
  backend "s3" {
    bucket         = "innovatemart-tfstate-aj-1272" 
    key            = "innovatemart-prod/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

