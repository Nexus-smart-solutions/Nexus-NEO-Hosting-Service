# =================================================================
# TERRAFORM OUTPUTS
# =================================================================

output "server_public_ip" {
  description = "Public IP address of the dedicated server"
  value       = aws_eip.server_ip.public_ip
}

output "elastic_ip" {
  description = "Elastic IP address assigned to server"
  value       = aws_eip.server_ip.public_ip
}

output "domain_name_servers" {
  description = "Name servers assigned to the hosted zone"
  value       = aws_route53_zone.customer_zone.name_servers
}

output "domain_status" {
  description = "Current status of domain registration"
  value       = aws_route53domains_registered_domain.domain_purchase.status_list
}

output "instance_id" {
  description = "EC2 instance identifier"
  value       = aws_instance.hosting_server.id
}

output "whm_url" {
  description = "WHM control panel access URL"
  value       = "https://${aws_eip.server_ip.public_ip}:2087"
}

output "cpanel_url" {
  description = "cPanel control panel access URL"
  value       = "https://${aws_eip.server_ip.public_ip}:2083"
}

output "webmail_url" {
  description = "Webmail access URL"
  value       = "https://${aws_eip.server_ip.public_ip}:2096"
}

output "website_url" {
  description = "Customer website URL"
  value       = "https://${var.customer_domain}"
}

output "ssh_connection_string" {
  description = "SSH connection command for server access"
  value       = "ssh -i your-key.pem ec2-user@${aws_eip.server_ip.public_ip}"
}

output "backup_bucket_name" {
  description = "S3 bucket name for automated backups"
  value       = aws_s3_bucket.backups.id
}

output "customer_domain" {
  description = "Customer domain name"
  value       = var.customer_domain
}

output "customer_email" {
  description = "Customer email address"
  value       = var.customer_email
}

output "plan_tier" {
  description = "Selected hosting plan tier"
  value       = local.tier_name
}

output "provisioned_at" {
  description = "Infrastructure provisioning timestamp"
  value       = timestamp()
}
