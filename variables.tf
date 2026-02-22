# ================================================================
# NEO VPS SAAS - ROOT VARIABLES
# ================================================================
# Complete variable definitions for the NEO platform
# ================================================================

# ================================================================
# CUSTOMER INFORMATION
# ================================================================

variable "customer_id" {
  description = "Unique customer identifier (lowercase alphanumeric with hyphens)"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.customer_id))
    error_message = "Customer ID must be lowercase alphanumeric with hyphens only"
  }
}

variable "customer_domain" {
  description = "Primary domain name for the customer"
  type        = string
  
  validation {
    condition     = can(regex("^([a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,}$", var.customer_domain))
    error_message = "Must be a valid domain name (lowercase)"
  }
}

variable "customer_email" {
  description = "Customer primary email address"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.customer_email))
    error_message = "Must be a valid email address"
  }
}

# ================================================================
# PLAN SELECTION (NEW!)
# ================================================================

variable "plan_slug" {
  description = "Selected plan tier (core, scale, or titan)"
  type        = string
  default     = "core"
  
  validation {
    condition     = contains(["core", "scale", "titan"], var.plan_slug)
    error_message = "Plan must be one of: core, scale, titan"
  }
}

# ================================================================
# MARKETPLACE ADD-ONS (NEW!)
# ================================================================

variable "marketplace_addons" {
  description = "List of marketplace add-on IDs to provision"
  type        = list(string)
  default     = []
  
  # Example: ["storage-ebs-100", "security-waf", "email-ses"]
}

# ================================================================
# SERVER CONFIGURATION
# ================================================================
# Note: These can be overridden by plan enforcement
# If plan_slug is set, these values come from the plan
# ================================================================

variable "os_type" {
  description = "Operating system type"
  type        = string
  default     = "almalinux-8"
  
  validation {
    condition = contains([
      "almalinux-8",
      "almalinux-9",
      "ubuntu-20.04",
      "ubuntu-22.04",
      "ubuntu-24.04",
      "rocky-8",
      "rocky-9"
    ], var.os_type)
    error_message = "OS type must be one of: almalinux-8, almalinux-9, ubuntu-20.04, ubuntu-22.04, ubuntu-24.04, rocky-8, rocky-9"
  }
}

variable "control_panel" {
  description = "Control panel to install"
  type        = string
  default     = "cyberpanel"
  
  validation {
    condition     = contains(["cpanel", "cyberpanel", "directadmin", "none"], var.control_panel)
    error_message = "Control panel must be one of: cpanel, cyberpanel, directadmin, none"
  }
}

variable "instance_type" {
  description = "EC2 instance type (overridden by plan if plan_slug is set)"
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Root volume size in GB (overridden by plan if plan_slug is set)"
  type        = number
  default     = 30
  
  validation {
    condition     = var.root_volume_size >= 20 && var.root_volume_size <= 1000
    error_message = "Root volume size must be between 20 and 1000 GB"
  }
}

variable "data_volume_size" {
  description = "Data volume size in GB (overridden by plan if plan_slug is set)"
  type        = number
  default     = 50
  
  validation {
    condition     = var.data_volume_size >= 20 && var.data_volume_size <= 5000
    error_message = "Data volume size must be between 20 and 5000 GB"
  }
}

variable "ssh_key_name" {
  description = "SSH key pair name for instance access"
  type        = string
}

# ================================================================
# NETWORK CONFIGURATION
# ================================================================

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid CIDR block"
  }
}

variable "admin_cidrs" {
  description = "List of CIDR blocks allowed to SSH (leave empty for any)"
  type        = list(string)
  default     = []
}

# ================================================================
# DNS CONFIGURATION
# ================================================================

variable "enable_route53" {
  description = "Enable Route53 DNS automation (or use Bind9)"
  type        = bool
  default     = false
}

variable "enable_mail_records" {
  description = "Create mail-related DNS records (MX, SPF, DMARC)"
  type        = bool
  default     = true
}

variable "enable_custom_nameservers" {
  description = "Use custom nameservers instead of AWS defaults"
  type        = bool
  default     = true
}

variable "ns1_ip" {
  description = "Primary nameserver IP (Bind9)"
  type        = string
  default     = ""
}

variable "ns2_ip" {
  description = "Secondary nameserver IP (Bind9)"
  type        = string
  default     = ""
}

# ================================================================
# GENERAL SETTINGS
# ================================================================

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment name (production, staging, development)"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be: production, staging, or development"
  }
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}

# ================================================================
# FEATURE FLAGS
# ================================================================

variable "enable_backups" {
  description = "Enable automated backups (recommended)"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling (Titan plan only)"
  type        = bool
  default     = false
}
