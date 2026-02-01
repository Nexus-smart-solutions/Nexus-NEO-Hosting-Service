# --- Domain Registration Info ---
variable "registrant_first_name" {
  description = "First name of the domain owner"
  type        = string
  default     = "Nexus"
}

variable "registrant_last_name" {
  description = "Last name of the domain owner"
  type        = string
  default     = "Customer"
}

variable "registrant_address" {
  description = "Street address for domain registration"
  type        = string
  default     = "Managed by Nexus NEO"
}

variable "registrant_city" {
  description = "City for domain registration"
  type        = string
  default     = "Dubai"
}

variable "registrant_country_code" {
  description = "ISO Country code (e.g., AE, US, EG)"
  type        = string
  default     = "AE"
}

variable "registrant_zip_code" {
  description = "Zip/Postal code"
  type        = string
  default     = "00000"
}

variable "registrant_phone" {
  description = "Phone number in +CountryCode.Number format"
  type        = string
  default     = "+971.000000000"
}
