# ===================================
# CPANEL SERVER MODULE VARIABLES
# ===================================

variable "customer_domain" {
  description = "Customer domain name (will be hostname)"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where server will be deployed"
  type        = string
}

variable "security_group_id" {
  description = "Security Group ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 50
}

variable "data_volume_size" {
  description = "Data volume size in GB for /home"
  type        = number
  default     = 100
}

variable "enable_backups" {
  description = "Enable S3 backups"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 30
}

variable "enable_monitoring" {
  description = "Enable CloudWatch detailed monitoring"
  type        = bool
  default     = true
}

variable "admin_email" {
  description = "Admin email for notifications"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
