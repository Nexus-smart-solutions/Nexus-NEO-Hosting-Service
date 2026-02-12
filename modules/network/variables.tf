# ===================================
# NETWORK MODULE VARIABLES
# ===================================

variable "customer_domain" {
  description = "Customer domain name (used for naming resources)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]\\.[a-z]{2,}$", var.customer_domain))
    error_message = "Customer domain must be a valid domain name (e.g., example.com)"
  }
}

variable "environment" {
  description = "Environment name (production, staging, development)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be production, staging, or development"
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

# ===================================
# VPC CONFIGURATION
# ===================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block"
  }
}

# ===================================
# SUBNETS CONFIGURATION
# ===================================

variable "availability_zones" {
  description = "List of availability zones in Ohio (us-east-2)"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 1
    error_message = "At least one public subnet CIDR is required"
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 1
    error_message = "At least one private subnet CIDR is required"
  }
}

# ===================================
# NAT GATEWAY CONFIGURATION
# ===================================

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

# ===================================
# VPC FLOW LOGS
# ===================================

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

# ===================================
# VPC ENDPOINTS
# ===================================

variable "enable_s3_endpoint" {
  description = "Enable S3 VPC Endpoint (Gateway type - free)"
  type        = bool
  default     = true
}

# ===================================
# DNS CONFIGURATION (Added to fix CI errors)
# ===================================

variable "enable_custom_dns" {
  description = "Enable custom DNS server infrastructure"
  type        = bool
  default     = false
}

variable "enable_secondary_dns" {
  description = "Enable secondary DNS server"
  type        = bool
  default     = false
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed to access DNS server (SSH)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "backup_bucket" {
  description = "S3 bucket name for DNS backups"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "Existing VPC ID (optional - used if VPC created outside this module)"
  type        = string
  default     = null
}

# ===================================
# TAGS
# ===================================

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
