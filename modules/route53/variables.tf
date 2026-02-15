# ================================================================
# ROUTE53 MODULE - VARIABLES
# ================================================================

variable "customer_id" {
  description = "Unique customer identifier"
  type        = string
}

variable "domain" {
  description = "Domain name for the hosted zone"
  type        = string
  
  validation {
    condition     = can(regex("^([a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,}$", var.domain))
    error_message = "Domain must be a valid domain name"
  }
}

variable "server_ip" {
  description = "Server IP address for A records"
  type        = string
  
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.server_ip))
    error_message = "Must be a valid IPv4 address"
  }
}

variable "environment" {
  description = "Environment (production, staging, development)"
  type        = string
  default     = "production"
}

variable "panel_type" {
  description = "Control panel type (cpanel, cyberpanel, directadmin, none)"
  type        = string
  default     = "none"
}

# Mail Configuration
variable "enable_mail_records" {
  description = "Enable mail-related DNS records (MX, TXT, etc.)"
  type        = bool
  default     = true
}

variable "mail_server_ip" {
  description = "Mail server IP (defaults to server_ip if not provided)"
  type        = string
  default     = ""
}

# Custom Nameservers (Bind9)
variable "enable_custom_nameservers" {
  description = "Use custom nameservers instead of AWS defaults"
  type        = bool
  default     = false
}

variable "ns1_ip" {
  description = "Primary nameserver IP (for custom NS)"
  type        = string
  default     = ""
}

variable "ns2_ip" {
  description = "Secondary nameserver IP (for custom NS)"
  type        = string
  default     = ""
}

# ========== إضافة السيرفرات الجديدة ==========
variable "enable_additional_nameservers" {
  description = "Enable additional nameservers (nsfs, nsfs9)"
  type        = bool
  default     = false
}

variable "ns3_ip" {
  description = "Third nameserver IP (nsfs)"
  type        = string
  default     = ""
}

variable "ns4_ip" {
  description = "Fourth nameserver IP (nsfs9)"
  type        = string
  default     = ""
}

# Health Check
variable "enable_health_check" {
  description = "Enable Route53 health check for the server"
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "SNS topic ARNs for health check alarms"
  type        = list(string)
  default     = []
}

# Tags
variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
