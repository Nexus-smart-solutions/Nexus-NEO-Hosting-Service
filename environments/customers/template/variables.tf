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

# --- Root Volume Defaults ---
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

# --- Domain Registration Defaults (Add these if not already there) ---
variable "registrant_first_name" { type = string; default = "Nexus" }
variable "registrant_last_name" { type = string; default = "Customer" }
variable "registrant_address" { type = string; default = "Managed by Nexus NEO" }
variable "registrant_city" { type = string; default = "Dubai" }
variable "registrant_country_code" { type = string; default = "AE" }
variable "registrant_zip_code" { type = string; default = "00000" }
variable "registrant_phone" { type = string; default = "+971.000000000" }
