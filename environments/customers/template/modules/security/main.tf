# ===================================
# SECURITY MODULE - CPANEL SECURITY GROUP
# ===================================

locals {
  name_prefix = "${var.customer_domain}-${var.environment}"
}

resource "aws_security_group" "cpanel" {
  name_prefix = "${local.name_prefix}-cpanel-sg-"
  description = "Security group for cPanel/WHM server - ${var.customer_domain}"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name     = "${local.name_prefix}-cpanel-sg"
      Customer = var.customer_domain
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ===================================
# SSH ACCESS
# ===================================

resource "aws_security_group_rule" "ssh" {
  count = length(var.allowed_ssh_cidrs) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ssh_cidrs
  security_group_id = aws_security_group.cpanel.id
  description       = "SSH access"
}

# ===================================
# WEB PORTS (HTTP/HTTPS)
# ===================================

resource "aws_security_group_rule" "http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cpanel.id
  description       = "HTTP"
}

resource "aws_security_group_rule" "https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cpanel.id
  description       = "HTTPS"
}

# ===================================
# CPANEL/WHM ADMIN PORTS
# ===================================

resource "aws_security_group_rule" "whm" {
  count = length(var.allowed_admin_cidrs) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = 2087
  to_port           = 2087
  protocol          = "tcp"
  cidr_blocks       = var.allowed_admin_cidrs
  security_group_id = aws_security_group.cpanel.id
  description       = "WHM Admin (2087)"
}

resource "aws_security_group_rule" "cpanel_https" {
  count = length(var.allowed_admin_cidrs) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = 2083
  to_port           = 2083
  protocol          = "tcp"
  cidr_blocks       = var.allowed_admin_cidrs
  security_group_id = aws_security_group.cpanel.id
  description       = "cPanel HTTPS (2083)"
}

resource "aws_security_group_rule" "webmail" {
  type              = "ingress"
  from_port         = 2096
  to_port           = 2096
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cpanel.id
  description       = "Webmail HTTPS (2096)"
}

# ===================================
# FTP PORTS
# ===================================

resource "aws_security_group_rule" "ftp" {
  type              = "ingress"
  from_port         = 21
  to_port           = 21
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cpanel.id
  description       = "FTP"
}

resource "aws_security_group_rule" "ftp_passive" {
  type              = "ingress"
  from_port         = 49152
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cpanel.id
  description       = "FTP Passive Mode"
}

# ===================================
# EMAIL PORTS
# ===================================

resource "aws_security_group_rule" "smtp" {
  type              = "ingress"
  from_port         = 25
  to_port           = 25
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cpanel.id
  description       = "SMTP"
}

resource "aws_security_group_rule" "smtp_submission" {
  type              = "ingress"
  from_port         = 587
  to_port           = 587
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cpanel.id
  description       = "SMTP Submission"
}

resource "aws_security_group_rule" "pop3" {
  type              = "ingress"
  from_port         = 110
  to_port           = 110
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cpanel.id
  description       = "POP3"
}

resource "aws_security_group_rule" "pop3s" {
  type              = "ingress"
  from_port         = 995
  to_port           = 995
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cpanel.id
  description       = "POP3S"
}

resource "aws_security_group_rule" "imap" {
  type              = "ingress"
  from_port         = 143
  to_port           = 143
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cpanel.id
  description       = "IMAP"
}

resource "aws_security_group_rule" "imaps" {
  type              = "ingress"
  from_port         = 993
  to_port           = 993
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cpanel.id
  description       = "IMAPS"
}

# ===================================
# DNS PORTS
# ===================================

resource "aws_security_group_rule" "dns_tcp" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cpanel.id
  description       = "DNS TCP"
}

resource "aws_security_group_rule" "dns_udp" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cpanel.id
  description       = "DNS UDP"
}

# ===================================
# EGRESS (OUTBOUND)
# ===================================

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cpanel.id
  description       = "Allow all outbound"
}
