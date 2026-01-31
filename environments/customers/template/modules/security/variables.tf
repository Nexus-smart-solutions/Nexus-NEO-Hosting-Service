# ===================================
# SECURITY MODULE VARIABLES
# ===================================

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "customer_domain" {
  description = "Customer domain name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = []
}

variable "allowed_admin_cidrs" {
  description = "CIDR blocks allowed for WHM/cPanel admin access"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
