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
	tls = {
    source  = "hashicorp/tls"
    version = "~> 4.0"
  }
  }

  backend "s3" {
    bucket         = "openproject-odoo-tfstate-209556027151"
    key            = "openproject-odoo/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "openproject-odoo-tflock"
    encrypt        = true
  }
}

provider "aws" {
  region  = var.aws_region
  

  default_tags {
    tags = {
      Project     = "openproject-odoo"
      Environment = "portfolio-demo"
      ManagedBy   = "terraform"
    }
  }
}