# ===================================
# TEMPLATE VARIABLES
# ===================================
# Variables expected by GitHub Actions workflow

# Required by workflow
variable "customer_domain" {
  description = "Customer domain name"
  type        = string
}

variable "customer_email" {
  description = "Customer email address (from workflow)"
  type        = string
}

variable "plan_tier" {
  description = "Hosting plan tier (basic/standard/premium) - from workflow"
  type        = string
}

variable "client_id" {
  description = "Unique customer identifier - from workflow"
  type        = string
}

# DNS Configuration
variable "hosted_zone_name" {
  description = "The name of the parent hosted zone in Route 53"
  type        = string
  default     = "nexus-dxb.com"
}

# Additional required variables
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2" # Set to us-east-2 to match your workflow region
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 50
}

variable "data_volume_size" {
  description = "Data volume size in GB"
  type        = number
}

variable "enable_backups" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 30
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}

# Alias for compatibility
variable "admin_email" {
  description = "Admin email (alias for customer_email)"
  type        = string
  default     = ""
}

# Computed internally
locals {
  # Use customer_email if admin_email is not provided
  final_admin_email = var.admin_email != "" ? var.admin_email : var.customer_email
  
  # Map plan_tier to actual tier name
  tier_name = lower(var.plan_tier)
}
