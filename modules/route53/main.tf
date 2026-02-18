# ================================================================
# ROUTE53 DNS MODULE
# ================================================================
# Production-ready DNS automation for customer domains
# Features: Hosted zones, A/MX/TXT records, health checks
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

# ================================================================
# LOCALS
# ================================================================

locals {
  # Common tags
  common_tags = merge(var.tags, {
    Module    = "route53"
    Customer  = var.customer_id
    Domain    = var.domain
    ManagedBy = "Terraform"
  })

  # DNS Records TTLs
  default_ttl = 300
  ns_ttl      = 172800 # 2 days for NS records
  mx_ttl      = 3600   # 1 hour for MX records
}

# ================================================================
# HOSTED ZONE
# ================================================================

resource "aws_route53_zone" "main" {
  name          = var.domain
  comment       = "Managed by NEO VPS for ${var.customer_id}"
  force_destroy = var.environment != "production"

  tags = merge(local.common_tags, {
    Name = "${var.domain}-hosted-zone"
  })
}

# ================================================================
# A RECORDS
# ================================================================

# Root domain A record
resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "A"
  ttl     = local.default_ttl
  records = [var.server_ip]
}

# WWW subdomain A record
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain}"
  type    = "A"
  ttl     = local.default_ttl
  records = [var.server_ip]
}

# Mail server A record
resource "aws_route53_record" "mail" {
  count   = var.enable_mail_records ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "mail.${var.domain}"
  type    = "A"
  ttl     = local.default_ttl
  records = [var.mail_server_ip != "" ? var.mail_server_ip : var.server_ip]
}

# ================================================================
# CUSTOM NAMESERVERS (if using Bind9)
# ================================================================

# NS1 A record
resource "aws_route53_record" "ns1" {
  count   = var.enable_custom_nameservers ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "ns1.${var.domain}"
  type    = "A"
  ttl     = local.default_ttl
  records = [var.ns1_ip]
}

# NS2 A record
resource "aws_route53_record" "ns2" {
  count   = var.enable_custom_nameservers ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "ns2.${var.domain}"
  type    = "A"
  ttl     = local.default_ttl
  records = [var.ns2_ip]
}

# ========== إضافة السيرفرات الجديدة ==========
# NSFS A record
resource "aws_route53_record" "nsfs" {
  count   = var.enable_additional_nameservers ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "nsfs.${var.domain}"
  type    = "A"
  ttl     = local.default_ttl
  records = [var.ns3_ip]
}

# NSFS9 A record
resource "aws_route53_record" "nsfs9" {
  count   = var.enable_additional_nameservers ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "nsfs9.${var.domain}"
  type    = "A"
  ttl     = local.default_ttl
  records = [var.ns4_ip]
}

# Custom NS records (override AWS nameservers)
resource "aws_route53_record" "custom_ns" {
  count   = var.enable_custom_nameservers ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "NS"
  ttl     = local.ns_ttl

  records = concat(
    [
      "ns1.${var.domain}",
      "ns2.${var.domain}"
    ],
    var.enable_additional_nameservers ? [
      "nsfs.${var.domain}",
      "nsfs9.${var.domain}"
    ] : []
  )
}

# ================================================================
# MX RECORDS
# ================================================================

resource "aws_route53_record" "mx" {
  count   = var.enable_mail_records ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "MX"
  ttl     = local.mx_ttl

  records = [
    "10 mail.${var.domain}"
  ]
}

# ================================================================
# TXT RECORDS (SPF, DMARC, DKIM)
# ================================================================

# SPF Record
resource "aws_route53_record" "spf" {
  count   = var.enable_mail_records ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "TXT"
  ttl     = local.default_ttl

  records = [
    "v=spf1 mx a ip4:${var.server_ip} ~all"
  ]
}

# DMARC Record
resource "aws_route53_record" "dmarc" {
  count   = var.enable_mail_records ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "_dmarc.${var.domain}"
  type    = "TXT"
  ttl     = local.default_ttl

  records = [
    "v=DMARC1; p=quarantine; rua=mailto:postmaster@${var.domain}"
  ]
}

# ================================================================
# CNAME RECORDS (Common services)
# ================================================================

# FTP
resource "aws_route53_record" "ftp" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "ftp.${var.domain}"
  type    = "CNAME"
  ttl     = local.default_ttl
  records = [var.domain]
}

# Webmail
resource "aws_route53_record" "webmail" {
  count   = var.enable_mail_records ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "webmail.${var.domain}"
  type    = "CNAME"
  ttl     = local.default_ttl
  records = [var.domain]
}

# cPanel
resource "aws_route53_record" "cpanel" {
  count   = var.panel_type == "cpanel" ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "cpanel.${var.domain}"
  type    = "CNAME"
  ttl     = local.default_ttl
  records = [var.domain]
}

# WHM
resource "aws_route53_record" "whm" {
  count   = var.panel_type == "cpanel" ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "whm.${var.domain}"
  type    = "CNAME"
  ttl     = local.default_ttl
  records = [var.domain]
}

# ================================================================
# HEALTH CHECK (for critical domains)
# ================================================================

resource "aws_route53_health_check" "server" {
  count             = var.enable_health_check ? 1 : 0
  ip_address        = var.server_ip
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 30

  tags = merge(local.common_tags, {
    Name = "${var.domain}-health-check"
  })
}

# CloudWatch Alarm for health check
resource "aws_cloudwatch_metric_alarm" "health_check" {
  count               = var.enable_health_check ? 1 : 0
  alarm_name          = "${var.customer_id}-dns-health-check"
  alarm_description   = "Route53 health check failed for ${var.domain}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  treat_missing_data  = "breaching"

  alarm_actions = var.alarm_actions

  dimensions = {
    HealthCheckId = aws_route53_health_check.server[0].id
  }

  tags = local.common_tags
}

# ================================================================
# OUTPUTS
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
