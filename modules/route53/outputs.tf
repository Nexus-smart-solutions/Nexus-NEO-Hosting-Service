# ================================================================
# ROUTE53 MODULE - OUTPUTS
# ================================================================

output "zone_id" {
  description = "The hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "zone_arn" {
  description = "The hosted zone ARN"
  value       = aws_route53_zone.main.arn
}

output "name_servers" {
  description = "List of name servers for the hosted zone"
  value       = aws_route53_zone.main.name_servers
}

output "custom_name_servers" {
  description = "Custom name servers (if enabled)"
  value = var.enable_custom_nameservers ? [
    "ns1.${var.domain}",
    "ns2.${var.domain}"
  ] : []
}

output "zone_name" {
  description = "The domain name"
  value       = aws_route53_zone.main.name
}

output "health_check_id" {
  description = "Health check ID (if enabled)"
  value       = var.enable_health_check ? aws_route53_health_check.server[0].id : null
}

output "dns_records" {
  description = "Summary of created DNS records"
  value = {
    root_domain = "${var.domain} → ${var.server_ip}"
    www         = "www.${var.domain} → ${var.server_ip}"
    mail        = var.enable_mail_records ? "mail.${var.domain} → ${var.mail_server_ip != "" ? var.mail_server_ip : var.server_ip}" : "disabled"
    mx          = var.enable_mail_records ? "10 mail.${var.domain}" : "disabled"
    nameservers = var.enable_custom_nameservers ? "ns1/ns2.${var.domain}" : "AWS managed"
  }
}
