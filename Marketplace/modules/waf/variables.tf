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

variable "resource_arn" {
  description = "ARN of ALB to associate with WAF"
  type        = string
  default     = ""
}

variable "rate_limit" {
  description = "Rate limit per IP (requests per 5 minutes)"
  type        = number
  default     = 2000
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "enable_logging" {
  description = "Enable WAF logging to CloudWatch"
  type        = bool
  default     = false
}

variable "create_dashboard" {
  description = "Create CloudWatch dashboard for WAF"
  type        = bool
  default     = false
}
