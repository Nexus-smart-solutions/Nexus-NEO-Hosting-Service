# ================================================================
# ROUTE53 MODULE - OUTPUTS (UPDATED)
# ================================================================
# Add these outputs to your existing outputs.tf file
# Or replace the existing outputs section
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
  description = "AWS name servers for the hosted zone"
  value       = aws_route53_zone.main.name_servers
}

output "custom_name_servers" {
  description = "Custom name servers (if enabled)"
  value = var.enable_custom_nameservers ? [
    "ns1.${var.domain}",
    "ns2.${var.domain}"
  ] : []
}

# ========== NEW OUTPUTS ==========

output "all_nameservers" {
  description = "All configured nameservers including additional ones"
  value = concat(
    var.enable_custom_nameservers ? [
      "ns1.${var.domain}",
      "ns2.${var.domain}"
    ] : [],
    var.enable_additional_nameservers ? [
      "nsfs.${var.domain}",
      "nsfs9.${var.domain}"
    ] : []
  )
}

output "additional_nameservers" {
  description = "Additional nameserver details"
  value = var.enable_additional_nameservers ? {
    nsfs = {
      hostname = "nsfs.${var.domain}"
      ip       = var.ns3_ip
    }
    nsfs9 = {
      hostname = "nsfs9.${var.domain}"
      ip       = var.ns4_ip
    }
  } : {}
}

output "zone_name" {
  description = "The domain name"
  value       = aws_route53_zone.main.name
}

# ========== DNS SERVER IPs ==========

output "dns_server_ips" {
  description = "All DNS server IPs"
  value = {
    ns1   = var.enable_custom_nameservers ? var.ns1_ip : null
    ns2   = var.enable_custom_nameservers ? var.ns2_ip : null
    nsfs  = var.enable_additional_nameservers ? var.ns3_ip : null
    nsfs9 = var.enable_additional_nameservers ? var.ns4_ip : null
  }
}
