# ===================================
# WAF MODULE - VARIABLES
# ===================================

variable "customer_id" {
  description = "Customer identifier"
  type        = string
}

variable "customer_domain" {
  description = "Customer domain"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "scope" {
  description = "WAF scope (REGIONAL or CLOUDFRONT)"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "Scope must be REGIONAL or CLOUDFRONT"
  }
}

variable "resource_arn" {
  description = "ARN of resource to associate with WAF (ALB or CloudFront)"
  type        = string
  default     = ""
}

variable "rate_limit" {
  description = "Rate limit per IP (requests per 5 minutes)"
  type        = number
  default     = 2000
}

variable "blocked_countries" {
  description = "List of country codes to block"
  type        = list(string)
  default     = []
}

variable "enable_logging" {
  description = "Enable WAF logging to CloudWatch"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Days to retain WAF logs"
  type        = number
  default     = 30
}

variable "create_dashboard" {
  description = "Create CloudWatch dashboard for WAF"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
