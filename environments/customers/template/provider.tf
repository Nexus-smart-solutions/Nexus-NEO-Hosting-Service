# ===================================
# TERRAFORM & PROVIDER CONFIGURATION
# ===================================

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
  
  default_tags {
    tags = merge(
      var.tags,
      {
        ManagedBy   = "Terraform"
        Environment = var.environment
        Customer    = var.customer_domain
      }
    )
  }
}
