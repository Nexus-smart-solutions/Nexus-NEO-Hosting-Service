# ===================================
# NEO VPS PROVISIONING SYSTEM - VARIABLES
# ===================================

# ===================================
# REQUIRED VARIABLES
# ===================================

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

# ===================================
# AWS CONFIGURATION
# ===================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production"
  }
}

# ===================================
# SERVER CONFIGURATION
# ===================================

variable "os_type" {
  description = "Operating system type"
  type        = string
  default     = "almalinux"
  
  validation {
    condition     = contains(["almalinux", "ubuntu"], var.os_type)
    error_message = "OS type must be almalinux or ubuntu"
  }
}

variable "os_version" {
  description = "OS version (e.g., 8, 9, 22.04)"
  type        = string
  default     = "8"
  
  validation {
    condition     = can(regex("^[0-9.]+$", var.os_version))
    error_message = "OS version must be a valid version number"
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
  default     = 50
}

variable "data_volume_size" {
  description = "Data volume size in GB"
  type        = number
  default     = 100
}

# ===================================
# NETWORKING
# ===================================

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "admin_cidrs" {
  description = "List of CIDR blocks allowed for admin access"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Change this in production!
}

# ===================================
# KEY PAIR CONFIGURATION
# ===================================

variable "create_key_pair" {
  description = "Create a new key pair"
  type        = bool
  default     = false
}

variable "public_key" {
  description = "Public key material (required if create_key_pair = true)"
  type        = string
  default     = ""
}

variable "existing_key_pair" {
  description = "Name of existing key pair (required if create_key_pair = false)"
  type        = string
  default     = ""
}

# ===================================
# BACKUP CONFIGURATION
# ===================================

variable "backup_retention_days" {
  description = "Number of days to retain backups in S3"
  type        = number
  default     = 30
}

# ===================================
# FEATURE FLAGS
# ===================================

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "enable_daily_snapshots" {
  description = "Enable daily EBS snapshots"
  type        = bool
  default     = false
}

variable "snapshot_retention_days" {
  description = "Number of days to retain snapshots"
  type        = number
  default     = 7
}

variable "allocate_eip" {
  description = "Allocate Elastic IP"
  type        = bool
  default     = true
}

variable "enable_route53" {
  description = "Enable Route53 DNS management"
  type        = bool
  default     = false
}

variable "enable_mail_records" {
  description = "Enable mail DNS records"
  type        = bool
  default     = false
}

variable "enable_custom_nameservers" {
  description = "Enable custom nameservers"
  type        = bool
  default     = false
}

variable "ns1_ip" {
  description = "IP for ns1 custom nameserver"
  type        = string
  default     = ""
}

variable "ns2_ip" {
  description = "IP for ns2 custom nameserver"
  type        = string
  default     = ""
}

variable "enable_enhanced_monitoring" {
  description = "Enable enhanced monitoring with dashboards"
  type        = bool
  default     = false
}

variable "create_dashboard" {
  description = "Create CloudWatch dashboard"
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  type        = string
  default     = ""
}

# ===================================
# AMI CONFIGURATION
# ===================================

variable "use_custom_ami" {
  description = "Use custom AMI instead of golden AMI"
  type        = bool
  default     = false
}

variable "custom_ami_id" {
  description = "Custom AMI ID (required if use_custom_ami = true)"
  type        = string
  default     = ""
}

# ===================================
# PANEL HOSTNAME
# ===================================

variable "panel_hostname" {
  description = "Custom panel hostname (e.g., panel.example.com)"
  type        = string
  default     = ""
}

# ===================================
# TAGS
# ===================================

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
