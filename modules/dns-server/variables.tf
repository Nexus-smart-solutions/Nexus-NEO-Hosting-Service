variable "ami_id" {
  description = "AMI ID for DNS server (AlmaLinux 8)"
  type        = string
  default     = "ami-03688ae343e09f184" #  AlmaLinux AMI
}

variable "subnet_id" {
  description = "Subnet ID for DNS server"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone (must be different from primary)"
  type        = string
  default     = "us-east-2b"
}

variable "primary_dns_ip" {
  description = "Primary DNS server IP"
  type        = string
  default     = "18.191.22.15"
}

variable "domain_suffix" {
  description = "Domain suffix for NS records"
  type        = string
  default     = "neo-vps.com"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
