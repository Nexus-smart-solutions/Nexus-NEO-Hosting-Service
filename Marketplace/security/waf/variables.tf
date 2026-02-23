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

variable "alb_arn" {
  description = "ARN of ALB to associate with WAF"
  type        = string
  default     = ""
}

variable "rate_limit" {
  description = "Rate limit per IP (requests per 5 minutes)"
  type        = number
  default     = 2000
}

variable "enable_logging" {
  description = "Enable WAF logging"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Days to retain WAF logs"
  type        = number
  default     = 30
}

variable "enable_managed_rules" {
  description = "Enable AWS managed rule groups"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
