# =================================================================
# TERRAFORM CONFIGURATION & BACKEND
# =================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote backend configuration using existing S3 and DynamoDB
  backend "s3" {
    bucket         = "hosting-company-terraform-state-093063750620"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}

# =================================================================
# PROVIDER AND GENERAL VARIABLES
# =================================================================

provider "aws" {
  region = var.region
}

variable "region" {
  description = "Target AWS region for infrastructure deployment"
  type        = string
  default     = "us-east-2"
}

variable "organization_name" {
  description = "Standard prefix for organizational resource naming"
  type        = string
  default     = "hosting-company"
}

# =================================================================
# DYNAMIC CUSTOMER VARIABLES 
# =================================================================

variable "customer_domain" {
  description = "The domain name provided by the customer"
  type        = string
}

variable "customer_email" {
  description = "The email address of the customer"
  type        = string
}

variable "plan_tier" {
  description = "The subscription tier (basic, premium, etc.)"
  type        = string
}

variable "client_id" {
  description = "The unique identifier for the client"
  type        = string
}

# =================================================================
# INFRASTRUCTURE RESOURCES
# =================================================================

# S3 Bucket for Terraform State Storage
resource "aws_s3_bucket" "terraform_state" {
  bucket = "hosting-company-terraform-state-093063750620"

  tags = {
    Name        = "Terraform State Storage"
    Environment = "Core-Infrastructure"
    ManagedBy   = "Terraform"
  }
}

# Enable Object Versioning for state recovery
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform Lock Table"
    Environment = "Core-Infrastructure"
  }
}

# =================================================================
# DATA SOURCES AND OUTPUTS
# =================================================================

data "aws_caller_identity" "current" {}

output "state_bucket_name" {
  description = "The name of the S3 bucket used for state storage"
  value       = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table used for state locking"
  value       = aws_dynamodb_table.terraform_lock.name
}
