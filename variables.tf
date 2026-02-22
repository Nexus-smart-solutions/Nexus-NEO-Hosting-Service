# ================================================================
# NEO VPS SAAS - ROOT VARIABLES
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
# PLAN SELECTION
# ================================================================

variable "plan_slug" {
  description = "Selected plan tier (core, scale, titan)"
  type        = string
  default     = "core"

  validation {
    condition     = contains(["core", "scale", "titan"], var.plan_slug)
    error_message = "Plan must be one of: core, scale, titan"
  }
}

# ================================================================
# MARKETPLACE ADD-ONS
# ================================================================

variable "marketplace_addons" {
  description = "List of marketplace add-on IDs"
  type        = list(string)
  default     = []
}

# ================================================================
# SERVER CONFIG
# ================================================================

variable "os_type" {
  description = "Operating system type"
  type        = string
  default     = "almalinux-8"
}

variable "os_version" {
  description = "Optional OS version override"
  type        = string
  default     = ""
}

variable "control_panel" {
  description = "Control panel to install"
  type        = string
  default     = "cyberpanel"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "data_volume_size" {
  description = "Data volume size in GB"
  type        = number
  default     = 50
}

variable "ssh_key_name" {
  description = "SSH key pair name"
  type        = string
}

# ================================================================
# ADVANCED SERVER OPTIONS (Required by panel_server module)
# ================================================================

variable "create_key_pair" {
  description = "Create new SSH key pair"
  type        = bool
  default     = false
}

variable "public_key" {
  description = "Public key content if creating new key pair"
  type        = string
  default     = ""
}

variable "existing_key_pair" {
  description = "Use existing key pair name"
  type        = string
  default     = ""
}

variable "backup_retention_days" {
  description = "Retention days for backups"
  type        = number
  default     = 7
}

variable "enable_detailed_monitoring" {
  description = "Enable EC2 detailed monitoring"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "enable_daily_snapshots" {
  description = "Enable daily EBS snapshots"
  type        = bool
  default     = true
}

variable "snapshot_retention_days" {
  description = "Snapshot retention period"
  type        = number
  default     = 7
}

variable "allocate_eip" {
  description = "Allocate Elastic IP"
  type        = bool
  default     = true
}

variable "use_custom_ami" {
  description = "Use custom AMI instead of default lookup"
  type        = bool
  default     = false
}

variable "custom_ami_id" {
  description = "Custom AMI ID if use_custom_ami = true"
  type        = string
  default     = ""
}

variable "panel_hostname" {
  description = "Hostname for control panel"
  type        = string
  default     = "panel"
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
  description = "CIDRs allowed for SSH"
  type        = list(string)
  default     = []
}

# ================================================================
# DNS
# ================================================================

variable "enable_route53" {
  description = "Enable Route53 DNS"
  type        = bool
  default     = false
}

variable "enable_mail_records" {
  description = "Create mail DNS records"
  type        = bool
  default     = true
}

variable "enable_custom_nameservers" {
  description = "Use custom nameservers"
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
  description = "Environment"
  type        = string
  default     = "production"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

# ================================================================
# FEATURE FLAGS
# ================================================================

variable "enable_backups" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable monitoring"
  type        = bool
  default     = true
}

variable "enable_auto_scaling" {
  description = "Enable auto scaling"
  type        = bool
  default     = false
}
