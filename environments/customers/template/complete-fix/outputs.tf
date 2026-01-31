# ===================================
# OUTPUTS
# ===================================
# Terraform outputs for customer deployment

# Customer Information
output "customer_domain" {
  description = "Customer domain name"
  value       = var.customer_domain
}

output "customer_email" {
  description = "Customer email address"
  value       = var.customer_email
}

output "client_id" {
  description = "Customer client ID"
  value       = var.client_id
}

output "tier" {
  description = "Hosting plan tier"
  value       = local.tier_name
}

# Network Outputs
output "vpc_id" {
  description = "VPC identifier"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.network.public_subnet_ids
}

# Server Access Information
output "elastic_ip" {
  description = "Server public IP address"
  value       = module.cpanel_server.elastic_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = module.cpanel_server.instance_id
}

# Control Panel URLs
output "whm_url" {
  description = "WHM access URL"
  value       = module.cpanel_server.whm_url
}

output "cpanel_url" {
  description = "cPanel access URL"
  value       = module.cpanel_server.cpanel_url
}

output "webmail_url" {
  description = "Webmail access URL"
  value       = module.cpanel_server.webmail_url
}

# Backup Information
output "backup_bucket_name" {
  description = "S3 backup bucket name"
  value       = module.cpanel_server.backup_bucket_name
}

# DNS Configuration Instructions
output "dns_records" {
  description = "DNS records to configure"
  value = {
    main_domain = {
      type   = "A"
      name   = "@"
      value  = module.cpanel_server.elastic_ip
      ttl    = 300
    }
    cpanel_subdomain = {
      type   = "A"
      name   = "cpanel"
      value  = module.cpanel_server.elastic_ip
      ttl    = 300
    }
    ns1 = {
      type   = "A"
      name   = "ns1"
      value  = module.cpanel_server.elastic_ip
      ttl    = 300
    }
    ns2 = {
      type   = "A"
      name   = "ns2"
      value  = module.cpanel_server.elastic_ip
      ttl    = 300
    }
  }
}

# Next Steps
output "next_steps" {
  description = "Instructions for completing setup"
  value = <<-EOT
  
  ========================================
  Deployment Complete! 🎉
  ========================================
  
  Customer: ${var.customer_domain}
  Email: ${var.customer_email}
  Tier: ${local.tier_name}
  
  Next Steps:
  
  1. Configure DNS Records:
     - ${var.customer_domain} A ${module.cpanel_server.elastic_ip}
     - cpanel.${var.customer_domain} A ${module.cpanel_server.elastic_ip}
     - ns1.${var.customer_domain} A ${module.cpanel_server.elastic_ip}
     - ns2.${var.customer_domain} A ${module.cpanel_server.elastic_ip}
  
  2. Access Server:
     - WHM: ${module.cpanel_server.whm_url}
     - SSH: aws ssm start-session --target ${module.cpanel_server.instance_id}
  
  3. Install cPanel:
     - Run: sudo /root/install-cpanel.sh
     - Wait: 1-2 hours for installation
  
  4. Complete Setup:
     - Access WHM and complete initial configuration
     - Create customer's first account
     - Test email and websites
  
  ========================================
  EOT
}
