# ===================================
# SECURITY MODULE VARIABLES
# ===================================

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "customer_domain" {
  description = "Customer domain name (used for naming resources)"
  type        = string
}

variable "environment" {
  description = "Environment name (production, staging, development)"
  type        = string
  default     = "production"
}

# ===================================
# ACCESS CONTROL
# ===================================

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed for SSH access (Port 22). Leave empty to disable SSH access."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.allowed_ssh_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All SSH CIDR blocks must be valid IPv4 CIDR notation"
  }
}

variable "allowed_admin_cidrs" {
  description = "List of CIDR blocks allowed for cPanel/WHM admin access (Ports 2083, 2087). Leave empty to disable admin panel access from the internet."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.allowed_admin_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All admin CIDR blocks must be valid IPv4 CIDR notation"
  }
}

# ===================================
# TAGS
# ===================================

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
