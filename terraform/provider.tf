terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "s3" {
    bucket         = "openproject-odoo-tfstate-209556027151"
    key            = "openproject-odoo/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "openproject-odoo-tflock"
    encrypt        = true
    profile        = "default"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "default"

  default_tags {
    tags = {
      Project     = "openproject-odoo"
      Environment = "portfolio-demo"
      ManagedBy   = "terraform"
    }
  }
}