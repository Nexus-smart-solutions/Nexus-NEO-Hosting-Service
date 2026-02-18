# ================================================================
# SECONDARY DNS SERVER MODULE
# ================================================================
# Deploys secondary DNS server in a different AZ for redundancy
# ================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  common_tags = merge(var.tags, {
    Module    = "dns-server"
    Role      = "secondary-dns"
    ManagedBy = "Terraform"
  })
}

# ================================================================
# SECONDARY DNS INSTANCE
# ================================================================

resource "aws_instance" "secondary_dns" {
  ami           = var.ami_id
  instance_type = "t3.micro"

  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]

  key_name = var.key_name

  # Use a different AZ from the primary
  availability_zone = var.availability_zone

  user_data = templatefile("${path.module}/user-data/bind9-secondary.sh", {
    primary_dns_ip = var.primary_dns_ip
    domain_suffix  = var.domain_suffix
  })

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "neo-secondary-dns"
    Type = "DNS"
  })
}

# Elastic IP
resource "aws_eip" "secondary_dns" {
  instance = aws_instance.secondary_dns.id
  domain   = "vpc"

  tags = merge(local.common_tags, {
    Name = "neo-secondary-dns-eip"
  })
}

# ================================================================
# OUTPUTS
# ================================================================

output "instance_id" {
  value = aws_instance.secondary_dns.id
}

output "public_ip" {
  value = aws_eip.secondary_dns.public_ip
}

output "private_ip" {
  value = aws_instance.secondary_dns.private_ip
}
