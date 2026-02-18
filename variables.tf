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
  
  validation {
    condition     = var.use_custom_ami ? (var.custom_ami_id != "") : true
    error_message = "custom_ami_id must be provided when use_custom_ami is true"
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
