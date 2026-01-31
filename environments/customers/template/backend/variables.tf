variable "customer_domain" {
  description = "The domain name provided by the customer"
  type        = string
}

variable "customer_email" {
  description = "The email address of the customer"
  type        = string
}

variable "plan_tier" {
  description = "The subscription tier (basic, premium, etc.)"
  type        = string
}

variable "client_id" {
  description = "The unique identifier for the client"
  type        = string
}


variable "region" {
  description = "Target AWS region"
  type        = string
  default     = "us-east-2"
}

variable "organization_name" {
  description = "Standard prefix for organizational resource naming"
  type        = string
  default     = "hosting-company"
}
