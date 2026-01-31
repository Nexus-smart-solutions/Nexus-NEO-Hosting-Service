variable "customer_domain" {
  type = string
}

variable "customer_email" {
  type = string
}

variable "plan_tier" {
  type = string
}

variable "client_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-east-2"
}

variable "organization_name" {
  type    = string
  default = "hosting-company"
}
