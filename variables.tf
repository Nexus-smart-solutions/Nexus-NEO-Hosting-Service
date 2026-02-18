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
  
  # validation بسيط للـ AMI format
  validation {
    condition     = can(regex("^ami-", var.custom_ami_id)) || var.custom_ami_id == ""
    error_message = "Custom AMI ID must start with 'ami-' or be empty."
  }
}

# ===================================
# PANEL HOSTNAME
# ===================================

variable "panel_hostname" {
  description = "Custom panel hostname (e.g., panel.example.com)"
  type        = string
  default     = ""
  
  validation {
    condition     = var.panel_hostname == "" || can(regex("^([a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,}$", var.panel_hostname))
    error_message = "Panel hostname must be a valid domain name if provided"
  }
}
