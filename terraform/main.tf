# Specifies the required providers for this Terraform project.
# We need the AWS provider to interact with AWS services and the
# Kubernetes provider to interact with the EKS cluster later on.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.2.0"
}

# Configures the AWS provider.
# We are setting the region to 'us-east-1'. You can change this if needed.
# It's best practice to configure credentials via environment variables
# or IAM roles, not directly in the code.
provider "aws" {
  region = var.aws_region
}