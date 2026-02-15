# ================================================================
# NEO VPS - Outputs
# ================================================================

# ================================================================
# Customer Summary
# ================================================================

output "customer_summary" {
  description = "Customer deployment summary"
  value = {
    customer_id   = var.customer_id
    domain        = var.customer_domain
    control_panel = var.control_panel
    instance_type = var.instance_type
    environment   = var.environment
  }
}

# ================================================================
# Network Outputs
# ================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.network.public_subnet_ids
}

# ================================================================
# DNS Outputs
# ================================================================

output "dns_zone_id" {
  description = "Route53 hosted zone ID"
  value       = module.route53.zone_id
}

output "dns_nameservers" {
  description = "All configured nameservers"
  value       = module.route53.all_nameservers
}

output "dns_zone_name" {
  description = "DNS zone name"
  value       = module.route53.zone_name
}

# ================================================================
# Server Outputs (if deployed)
# ================================================================

output "server_ip" {
  description = "Panel server IP address"
  value       = var.deploy_server ? module.panel_server[0].public_ip : null
}

output "server_access_url" {
  description = "Server access URL"
  value       = var.deploy_server ? module.panel_server[0].access_url : null
}

# ================================================================
# Deployment Info
# ================================================================

output "deployment_info" {
  description = "Deployment information"
  value = {
    region      = var.aws_region
    environment = var.environment
    deployed_at = timestamp()
  }
}
