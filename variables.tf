# ================================================================
# NEO VPS - Variables
# ================================================================

# ================================================================
# CUSTOMER INFO
# ================================================================

variable "customer_id" {
  description = "Unique customer identifier"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.customer_id))
    error_message = "Customer ID must be lowercase alphanumeric with hyphens only"
  }
}

variable "customer_domain" {
  description = "Customer domain name"
  type        = string
  
  validation {
    condition     = can(regex("^([a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,}$", var.customer_domain))
    error_message = "Must be a valid domain name"
  }
}

variable "customer_email" {
  description = "Customer email address"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.customer_email))
    error_message = "Must be a valid email address"
  }
}

# ================================================================
# SERVER CONFIG
# ================================================================

variable "os_type" {
  description = "Operating system type"
  type        = string
  default     = "almalinux-8"
  
  validation {
    condition     = contains(["almalinux-8", "almalinux-9", "ubuntu-20.04", "ubuntu-22.04", "ubuntu-24.04", "rocky-8", "rocky-9"], var.os_type)
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
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "data_volume_size" {
  description = "Data volume size in GB"
  type        = number
  default     = 100
}

variable "ssh_key_name" {
  description = "SSH key pair name"
  type        = string
}

# ================================================================
# NETWORK
# ================================================================

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "admin_cidrs" {
  description = "Admin IP addresses for SSH access"
  type        = list(string)
  default     = []
}

# ================================================================
# DNS
# ================================================================

variable "enable_route53" {
  description = "Enable Route53 DNS automation"
  type        = bool
  default     = false
}

variable "enable_mail_records" {
  description = "Enable mail-related DNS records"
  type        = bool
  default     = true
}

variable "enable_custom_nameservers" {
  description = "Use custom nameservers (Bind9)"
  type        = bool
  default     = true
}

variable "ns1_ip" {
  description = "Primary nameserver IP"
  type        = string
  default     = ""
}

variable "ns2_ip" {
  description = "Secondary nameserver IP"
  type        = string
  default     = ""
}

# ================================================================
# GENERAL
# ================================================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
