variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type = string
}

variable "customer_id" {
  type = string
}

variable "customer_domain" {
  type = string
}

variable "control_panel" {
  type = string

  validation {
    condition     = contains(["cyberpanel", "cpanel", "directadmin", "none"], var.control_panel)
    error_message = "Invalid control panel selected."
  }
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
