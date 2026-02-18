# ===================================
# NEO VPS PROVISIONING SYSTEM - VARIABLES
# ===================================

# Required Variables
variable "customer_id" {
  description = "Unique customer identifier"
  type        = string
}

variable "customer_domain" {
  description = "Customer domain name"
  type        = string
}

variable "customer_email" {
  description = "Customer email address"
  type        = string
}

# AWS Configuration
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

# Server Configuration
variable "os_type" {
  description = "Operating system type"
  type        = string
  default     = "almalinux"
}

variable "os_version" {
  description = "OS version"
  type        = string
  default     = "8"
}

variable "control_panel" {
  description = "Control panel to install"
  type        = string
  default     = "cyberpanel"
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

# Networking
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "admin_cidrs" {
  description = "List of CIDR blocks allowed for admin access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Key Pair
variable "create_key_pair" {
  description = "Create a new key pair"
  type        = bool
  default     = false
}

variable "public_key" {
  description = "Public key material"
  type        = string
  default     = ""
}

variable "existing_key_pair" {
  description = "Name of existing key pair"
  type        = string
  default     = ""
}

# Backup
variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

# Feature Flags
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

# Monitoring Variables
variable "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Email for alerts"
  type        = string
  default     = "dev@nexus-dxb.com"
}

variable "slack_webhook" {
  description = "Slack webhook URL"
  type        = string
  default     = ""
}

variable "cpu_high_threshold" {
  description = "CPU threshold percentage"
  type        = number
  default     = 75
}

variable "disk_threshold" {
  description = "Disk usage threshold percentage"
  type        = number
  default     = 80
}

variable "memory_threshold" {
  description = "Memory usage threshold percentage"
  type        = number
  default     = 90
}

variable "enable_disk_alarm" {
  description = "Enable disk usage alarm"
  type        = bool
  default     = true
}

variable "enable_memory_alarm" {
  description = "Enable memory usage alarm"
  type        = bool
  default     = true
}

variable "create_dashboard" {
  description = "Create CloudWatch dashboard"
  type        = bool
  default     = false
}

variable "create_dashboard_with_python" {
  description = "Create dashboard using Python script"
  type        = bool
  default     = false
}

# CI/CD Variable
variable "ci_cd" {
  description = "Running in CI/CD environment"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
