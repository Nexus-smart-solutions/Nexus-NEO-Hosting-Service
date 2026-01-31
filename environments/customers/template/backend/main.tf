# =================================================================
# 1. TERRAFORM CONFIGURATION & BACKEND
# =================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "hosting-company-terraform-state-093063750620"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}

# =================================================================
# 2. PROVIDER
# =================================================================

provider "aws" {
  region = var.region
}

# =================================================================
# 3. VARIABLES 
# =================================================================

variable "region" {
  description = "Target AWS region"
  type        = string
  default     = "us-east-2"
}

variable "organization_name" {
  description = "Standard prefix"
  type        = string
  default     = "hosting-company"
}

variable "customer_domain" {
  type = string
}

variable "customer_email" {
  type = string
}

variable "plan_tier" {
  type = string
}

variable "client_id" {
  type = string
}

# =================================================================
# 4. INFRASTRUCTURE RESOURCES
# =================================================================

resource "aws_s3_bucket" "terraform_state" {
  bucket = "hosting-company-terraform-state-093063750620"
  tags = {
    Name        = "Terraform State Storage"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# =================================================================
# 5. DATA & OUTPUTS
# =================================================================

data "aws_caller_identity" "current" {}

output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_lock.name
}
