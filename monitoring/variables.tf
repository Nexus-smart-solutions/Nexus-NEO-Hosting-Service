# ===================================
# MONITORING MODULE - VARIABLES
# ===================================

variable "customer_id" {
  description = "Unique customer identifier"
  type        = string
}

variable "customer_domain" {
  description = "Customer domain name"
  type        = string
}

variable "instance_id" {
  description = "EC2 instance ID to monitor"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "sns_topic_arn" {
  description = "Existing SNS topic ARN"
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Email for alerts"
  type        = string
  default     = ""
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

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
