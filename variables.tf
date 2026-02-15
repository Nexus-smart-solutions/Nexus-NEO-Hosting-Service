# ================================================================
# NEO VPS - Variables
# ================================================================

# ================================================================
# AWS Configuration
# ================================================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment (development, staging, production)"
  type        = string
  default     = "production"
}

# ================================================================
# Project Configuration
# ================================================================

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "neo-vps"
}

# ================================================================
# Customer Information
# ================================================================

variable "customer_id" {
  description = "Customer unique identifier"
  type        = string
}

variable "customer_domain" {
  description = "Customer domain name"
  type        = string
}

# ================================================================
# Server Configuration
# ================================================================

variable "control_panel" {
  description = "Control panel type (cpanel, cyberpanel, directadmin, none)"
  type        = string
  default     = "cpanel"
  
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

variable "server_ip" {
  description = "Server IP address"
  type        = string
  default     = ""
}

variable "deploy_server" {
  description = "Whether to deploy the panel server"
  type        = bool
  default     = false
}

variable "ssh_key_name" {
  description = "SSH key pair name"
  type        = string
  default     = ""
}

# ================================================================
# Network Configuration
# ================================================================

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

# ================================================================
# DNS Configuration
# ================================================================

variable "enable_custom_nameservers" {
  description = "Use custom nameservers instead of AWS defaults"
  type        = bool
  default     = true
}

variable "ns1_ip" {
  description = "Primary nameserver IP"
  type        = string
  default     = "18.191.22.15"
}

variable "ns2_ip" {
  description = "Secondary nameserver IP"
  type        = string
  default     = ""
}

variable "enable_additional_nameservers" {
  description = "Enable additional nameservers (nsfs, nsfs9)"
  type        = bool
  default     = true
}

variable "ns3_ip" {
  description = "Third nameserver IP (nsfs)"
  type        = string
  default     = "54.152.161.12"
}

variable "ns4_ip" {
  description = "Fourth nameserver IP (nsfs9)"
  type        = string
  default     = "54.152.161.12"
}

# ================================================================
# Mail Configuration
# ================================================================

variable "enable_mail_records" {
  description = "Enable mail-related DNS records"
  type        = bool
  default     = true
}

variable "mail_server_ip" {
  description = "Mail server IP (defaults to server_ip if not provided)"
  type        = string
  default     = ""
}

# ================================================================
# Tags
# ================================================================

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
