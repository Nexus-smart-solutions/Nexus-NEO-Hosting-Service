# ===================================
# MULTI-PANEL SERVER MODULE - VARIABLES
# Neo VPS Provisioning System v2.0
# ===================================

# ===================================
# CUSTOMER INFORMATION
# ===================================

variable "customer_id" {
  description = "Unique customer identifier"
  type        = string
}

variable "customer_domain" {
  description = "Customer's primary domain name"
  type        = string

  validation {
    condition     = can(regex("^([a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,}$", var.customer_domain))
    error_message = "Domain must be a valid domain name"
  }
}

variable "customer_email" {
  description = "Customer email for notifications"
  type        = string
}

variable "environment" {
  description = "Environment (production, staging, development)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be production, staging, or development"
  }
}

# ===================================
# CONTROL PANEL SELECTION
# ===================================

variable "control_panel" {
  description = "Control panel to install"
  type        = string
  default     = "cyberpanel"

  validation {
    condition     = contains(["none", "cyberpanel", "cpanel", "directadmin"], var.control_panel)
    error_message = "Control panel must be: none, cyberpanel, cpanel, or directadmin"
  }
}

variable "panel_hostname" {
  description = "Hostname for the control panel (optional, defaults to panel.domain)"
  type        = string
  default     = ""
}

# ===================================
# OPERATING SYSTEM
# ===================================

variable "os_type" {
  description = "Operating system type"
  type        = string
  default     = "almalinux"

  validation {
    condition     = contains(["almalinux", "ubuntu", "rocky"], var.os_type)
    error_message = "OS type must be almalinux, ubuntu, or rocky"
  }
}

variable "os_version" {
  description = "Operating system version"
  type        = string
  default     = "8"
}

variable "use_custom_ami" {
  description = "Use a custom Golden AMI instead of public AMIs"
  type        = bool
  default     = false
}

variable "custom_ami_id" {
  description = "Custom AMI ID (if use_custom_ami is true)"
  type        = string
  default     = ""
}

# ===================================
# INSTANCE CONFIGURATION
# ===================================

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"

  validation {
    condition     = can(regex("^t[23]\\.(nano|micro|small|medium|large|xlarge|2xlarge)$", var.instance_type))
    error_message = "Instance type must be a valid t2 or t3 instance type"
  }
}

variable "root_volume_size" {
  description = "Size of root EBS volume in GB"
  type        = number
  default     = 50

  validation {
    condition     = var.root_volume_size >= 30 && var.root_volume_size <= 1000
    error_message = "Root volume size must be between 30 and 1000 GB"
  }
}

variable "data_volume_size" {
  description = "Size of data EBS volume in GB"
  type        = number
  default     = 100

  validation {
    condition     = var.data_volume_size >= 50 && var.data_volume_size <= 16384
    error_message = "Data volume size must be between 50 and 16384 GB"
  }
}

# ===================================
# NETWORK CONFIGURATION
# ===================================

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the instance"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for the instance"
  type        = string
}

variable "allocate_elastic_ip" {
  description = "Allocate and assign an Elastic IP"
  type        = bool
  default     = true
}

# ===================================
# SSH KEY CONFIGURATION
# ===================================

variable "create_key_pair" {
  description = "Create a new SSH key pair"
  type        = bool
  default     = false
}

variable "public_key" {
  description = "SSH public key content (if create_key_pair is true)"
  type        = string
  default     = ""
}

variable "existing_key_pair" {
  description = "Existing SSH key pair name (if create_key_pair is false)"
  type        = string
  default     = ""
}

# ===================================
# BACKUP CONFIGURATION
# ===================================

variable "backup_retention_days" {
  description = "Number of days to retain S3 backups"
  type        = number
  default     = 30

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 365
    error_message = "Backup retention must be between 1 and 365 days"
  }
}

variable "enable_daily_snapshots" {
  description = "Enable daily EBS snapshots"
  type        = bool
  default     = true
}

variable "snapshot_retention_days" {
  description = "Number of days to retain EBS snapshots"
  type        = number
  default     = 7

  validation {
    condition     = var.snapshot_retention_days >= 1 && var.snapshot_retention_days <= 365
    error_message = "Snapshot retention must be between 1 and 365 days"
  }
}

# ===================================
# MONITORING CONFIGURATION
# ===================================

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = false
}

# ===================================
# TAGS
# ===================================

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
