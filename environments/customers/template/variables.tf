# =================================================================
# REQUIRED VARIABLES FOR CUSTOMER PROVISIONING
# =================================================================

variable "customer_domain" {
  description = "Domain name for the customer"
  type        = string
}

variable "customer_email" {
  description = "Email address for the customer"
  type        = string
}

variable "plan_tier" {
  description = "Hosting plan (basic, standard, premium)"
  type        = string
  
  validation {
    condition     = contains(["basic", "standard", "premium"], lower(var.plan_tier))
    error_message = "Plan tier must be: basic, standard, or premium"
  }
}

variable "client_id" {
  description = "Unique identifier for the client"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "data_volume_size" {
  description = "Size of the extra EBS volume in GB"
  type        = number
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 50
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_backups" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention in days"
  type        = number
  default     = 30
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}

# =================================================================
# DOMAIN REGISTRATION VARIABLES
# =================================================================

variable "auto_register_domain" {
  description = "Automatically register domain via Route53"
  type        = bool
  default     = true
}

variable "domain_duration_years" {
  description = "Domain registration duration in years"
  type        = number
  default     = 1
  
  validation {
    condition     = var.domain_duration_years >= 1 && var.domain_duration_years <= 10
    error_message = "Duration must be between 1 and 10 years"
  }
}

variable "auto_renew_domain" {
  description = "Enable domain auto-renewal"
  type        = bool
  default     = true
}

variable "transfer_lock" {
  description = "Enable domain transfer lock"
  type        = bool
  default     = true
}

variable "privacy_protection" {
  description = "Enable WHOIS privacy protection"
  type        = bool
  default     = true
}

# =================================================================
# REGISTRANT CONTACT INFORMATION
# =================================================================

variable "registrant_first_name" {
  description = "Registrant first name"
  type        = string
  default     = "Nexus"
}

variable "registrant_last_name" {
  description = "Registrant last name"
  type        = string
  default     = "Customer"
}

variable "registrant_organization" {
  description = "Registrant organization name"
  type        = string
  default     = "Nexus NEO Hosting Services"
}

variable "registrant_email" {
  description = "Registrant email (defaults to customer_email if empty)"
  type        = string
  default     = ""
}

variable "registrant_phone" {
  description = "Registrant phone number in E.164 format"
  type        = string
  default     = "+971.000000000"
}

variable "registrant_address" {
  description = "Registrant street address"
  type        = string
  default     = "Managed by Nexus NEO"
}

variable "registrant_city" {
  description = "Registrant city"
  type        = string
  default     = "Dubai"
}

variable "registrant_state" {
  description = "Registrant state or province"
  type        = string
  default     = "Dubai"
}

variable "registrant_country_code" {
  description = "Registrant country code (ISO 3166-1 alpha-2)"
  type        = string
  default     = "AE"
}

variable "registrant_zip_code" {
  description = "Registrant postal or zip code"
  type        = string
  default     = "00000"
}

# =================================================================
# ADMIN CONTACT INFORMATION
# =================================================================

variable "admin_first_name" {
  description = "Admin contact first name (defaults to registrant if empty)"
  type        = string
  default     = ""
}

variable "admin_last_name" {
  description = "Admin contact last name (defaults to registrant if empty)"
  type        = string
  default     = ""
}

variable "admin_email" {
  description = "Admin contact email (defaults to registrant if empty)"
  type        = string
  default     = ""
}

variable "admin_phone" {
  description = "Admin contact phone (defaults to registrant if empty)"
  type        = string
  default     = ""
}

# =================================================================
# TECHNICAL CONTACT INFORMATION
# =================================================================

variable "tech_first_name" {
  description = "Technical contact first name (defaults to registrant if empty)"
  type        = string
  default     = ""
}

variable "tech_last_name" {
  description = "Technical contact last name (defaults to registrant if empty)"
  type        = string
  default     = ""
}

variable "tech_email" {
  description = "Technical contact email (defaults to registrant if empty)"
  type        = string
  default     = ""
}

variable "tech_phone" {
  description = "Technical contact phone (defaults to registrant if empty)"
  type        = string
  default     = ""
}

# =================================================================
# LOCAL VALUES
# =================================================================

locals {
  final_registrant_email = var.registrant_email != "" ? var.registrant_email : var.customer_email
  final_admin_email      = var.admin_email != "" ? var.admin_email : local.final_registrant_email
  final_tech_email       = var.tech_email != "" ? var.tech_email : local.final_registrant_email
  
  final_admin_first_name = var.admin_first_name != "" ? var.admin_first_name : var.registrant_first_name
  final_admin_last_name  = var.admin_last_name != "" ? var.admin_last_name : var.registrant_last_name
  final_admin_phone      = var.admin_phone != "" ? var.admin_phone : var.registrant_phone
  
  final_tech_first_name = var.tech_first_name != "" ? var.tech_first_name : var.registrant_first_name
  final_tech_last_name  = var.tech_last_name != "" ? var.tech_last_name : var.registrant_last_name
  final_tech_phone      = var.tech_phone != "" ? var.tech_phone : var.registrant_phone
  
  tier_name = lower(var.plan_tier)
  
  common_tags = merge(
    var.tags,
    {
      Customer    = var.customer_domain
      ClientID    = var.client_id
      Tier        = local.tier_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}
