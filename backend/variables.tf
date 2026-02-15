# ================================================================
# BACKEND VARIABLES
# ================================================================

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "neo-vps"
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-2"
}

variable "dr_region" {
  description = "DR AWS region"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "neo-terraform-state-ohio"
}

variable "dr_bucket_name" {
  description = "S3 bucket name for DR backups"
  type        = string
  default     = "neo-terraform-state-dr-virginia"
}

variable "lock_table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "neo-terraform-locks"
}
