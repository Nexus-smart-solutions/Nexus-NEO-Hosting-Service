# =================================================================
# TERRAFORM CONFIGURATION & BACKEND
# =================================================================

variable "customer_domain" { type = string }
variable "customer_email"  { type = string }
variable "plan_tier"       { type = string }
variable "client_id"       { type = string }
variable "region"          { type = string; default = "us-east-2" }

# ------------------------------------------

terraform {
  required_version = ">= 1.0"

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

provider "aws" {
  region = var.region
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

# Enable Object Versioning
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
  value = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_lock.name
}
