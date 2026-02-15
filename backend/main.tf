# ================================================================
# TERRAFORM BACKEND INFRASTRUCTURE
# ================================================================
# S3 Buckets for State Management & DR
# DynamoDB for State Locking
# ================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # This backend module uses local state
  backend "local" {
    path = "terraform.tfstate"
  }
}

# ================================================================
# PROVIDERS
# ================================================================

provider "aws" {
  region = var.primary_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Environment = "production"
      Purpose     = "backend-infrastructure"
    }
  }
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Environment = "production"
      Purpose     = "disaster-recovery"
    }
  }
}

# ================================================================
# PRIMARY S3 BUCKET (Ohio)
# ================================================================

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name
  
  lifecycle {
    prevent_destroy = true
  }
  
  tags = {
    Name       = "Terraform State Storage"
    Region     = var.primary_region
    RegionName = "Ohio"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

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
    id     = "abort-incomplete-multipart"
    status = "Enabled"
    
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ================================================================
# DR S3 BUCKET (N. Virginia)
# ================================================================

resource "aws_s3_bucket" "terraform_state_dr" {
  provider = aws.dr
  bucket   = var.dr_bucket_name
  
  tags = {
    Name       = "Terraform State DR Backup"
    Region     = var.dr_region
    RegionName = "N-Virginia"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.terraform_state_dr.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.terraform_state_dr.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.terraform_state_dr.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.terraform_state_dr.id
  
  rule {
    id     = "delete-old-backups"
    status = "Enabled"
    
    filter {
      prefix = "backup-"
    }
    
    expiration {
      days = 30
    }
  }
  
  rule {
    id     = "delete-old-versions"
    status = "Enabled"
    
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# ================================================================
# DYNAMODB TABLE (State Locking)
# ================================================================

resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
  
  point_in_time_recovery {
    enabled = true
  }
  
  server_side_encryption {
    enabled = true
  }
  
  tags = {
    Name   = "Terraform State Locks"
    Region = var.primary_region
  }
}
