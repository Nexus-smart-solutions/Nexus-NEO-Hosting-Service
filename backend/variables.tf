variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "state_bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "neo-tf-state-ohio"
}

variable "lock_table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "neo-terraform-locks"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}
