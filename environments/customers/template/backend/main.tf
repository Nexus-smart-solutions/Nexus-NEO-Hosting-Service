# ===================================
# S3 REMOTE BACKEND SETUP
# ===================================
# This configuration must be run ONCE to create backend infrastructure
# Run: terraform init && terraform apply

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
}

variable "region" {
  description = "AWS region for backend resources"
  type        = string
  default     = "us-east-1"
}

variable "organization_name" {
  description = "Your organization name (for naming)"
  type        = string
  default     = "hosting-company"
}

# ===================================
# S3 BUCKET FOR TERRAFORM STATE
# ===================================

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.organization_name}-terraform-state-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "backend"
    Purpose     = "Multi-tenant state storage"
  }
}

# Enable versioning for state file protection
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy to manage old versions
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# ===================================
# DYNAMODB TABLE FOR STATE LOCKING
# ===================================

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "${var.organization_name}-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "backend"
    Purpose     = "State locking for concurrent operations"
  }
}

# ===================================
# IAM POLICY FOR BACKEND ACCESS
# ===================================

resource "aws_iam_policy" "terraform_backend" {
  name        = "${var.organization_name}-terraform-backend-policy"
  description = "Policy for Terraform backend access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning"
        ]
        Resource = aws_s3_bucket.terraform_state.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.terraform_lock.arn
      }
    ]
  })
}

# ===================================
# OUTPUTS
# ===================================

data "aws_caller_identity" "current" {}

output "state_bucket_name" {
  description = "S3 bucket name for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.terraform_state.arn
}

output "lock_table_name" {
  description = "DynamoDB table name for state locking"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "lock_table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.terraform_lock.arn
}

output "backend_config" {
  description = "Backend configuration to use in customer deployments"
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    region         = var.region
    dynamodb_table = aws_dynamodb_table.terraform_lock.name
    encrypt        = true
  }
}

output "backend_config_example" {
  description = "Example backend configuration block"
  value = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.terraform_state.id}"
        key            = "customers/<DOMAIN>/terraform.tfstate"
        region         = "${var.region}"
        dynamodb_table = "${aws_dynamodb_table.terraform_lock.name}"
        encrypt        = true
      }
    }
  EOT
}
