variable "customer_id" {
  description = "Customer identifier"
  type        = string
}

variable "plan_slug" {
  description = "Plan slug (basic, professional, enterprise)"
  type        = string
  
  validation {
    condition     = contains(["basic", "professional", "enterprise"], var.plan_slug)
    error_message = "Plan must be one of: basic, professional, enterprise"
  }
}

variable "instance_type" {
  description = "EC2 instance type to validate"
  type        = string
}

variable "root_volume_size" {
  description = "Root volume size to validate"
  type        = number
}

variable "data_volume_size" {
  description = "Data volume size to validate"
  type        = number
}

variable "enable_quota_monitoring" {
  description = "Enable CloudWatch quota monitoring"
  type        = bool
  default     = true
}

variable "log_group_name" {
  description = "CloudWatch log group name for quota tracking"
  type        = string
  default     = "/neo/quotas"
}

variable "quota_alarm_actions" {
  description = "SNS topic ARNs for quota alarms"
  type        = list(string)
  default     = []
}
