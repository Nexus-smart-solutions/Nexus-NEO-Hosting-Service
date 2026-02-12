# ===================================
# TERRAFORM BACKEND INFRASTRUCTURE
# ===================================
# This creates the S3 bucket and DynamoDB table needed for
# storing Terraform state files securely for multiple customers

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
    tags = {
      Project    = "cPanel-Hosting-Platform"
      ManagedBy  = "Terraform"
      Purpose    = "Backend-Infrastructure"
      CreatedAt  = timestamp()
    }
  }
}

# ===================================
# DATA SOURCES
# ===================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ===================================
# S3 BUCKET FOR TERRAFORM STATE
# ===================================

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.bucket_prefix}-terraform-state-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "Terraform State Bucket"
    Description = "Multi-tenant Terraform state storage"
  }
}

# Enable versioning to keep state history
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption at rest
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

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ===================================
# DYNAMODB TABLE FOR STATE LOCKING
# ===================================

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "${var.bucket_prefix}-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Description = "Prevents concurrent terraform runs"
  }
}

# ===================================
# IAM POLICY FOR STATE ACCESS
# ===================================

resource "aws_iam_policy" "terraform_state_access" {
  name_prefix = "${var.bucket_prefix}-terraform-state-access-"
  description = "Policy for accessing Terraform state bucket and lock table"

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

  tags = {
    Name = "Terraform State Access Policy"
  }
}
