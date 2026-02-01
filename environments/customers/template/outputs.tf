# =================================================================
# OUTPUTS - DATA FOR BACKEND & CUSTOMER EMAIL
# =================================================================

# 1. The Public IP of the server (To show in the dashboard)
output "server_public_ip" {
  description = "The public IP address of the customer's dedicated server"
  value       = aws_eip.server_ip.public_ip
}

# 2. Name Servers (Very important for the customer to see)
output "domain_name_servers" {
  description = "The Name Servers assigned to the customer's hosted zone"
  value       = aws_route53_zone.customer_zone.name_servers
}

# 3. Domain Expiry (To track and notify the customer before renewal)
# Note: This attribute depends on the domain registration resource support
output "domain_status" {
  description = "Current status of the domain registration"
  value       = aws_route53domains_registered_domain.domain_purchase.status_list
}

# 4. Instance ID (For internal management/reboot/scaling)
output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.hosting_server.id
}

# 5. Connection String (Helper for SSH if needed by support)
output "ssh_connection_string" {
  description = "SSH connection string for the server"
  value       = "ssh - i your-key.pem ubuntu@${aws_eip.server_ip.public_ip}"
}

# 6. Website URL (The final product)
output "website_url" {
  description = "The final URL of the customer website"
  value       = "https://${var.customer_domain}"
}
