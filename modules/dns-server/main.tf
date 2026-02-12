# ==========================================
# BIND9 NAMESERVER MODULE
# Neo VPS Platform - Custom DNS Server
# ==========================================

# ==========================================
# EC2 INSTANCE FOR BIND9 DNS SERVER
# ==========================================

resource "aws_instance" "dns_server" {
  count         = var.enable_custom_dns ? 1 : 0
  ami           = data.aws_ami.dns_server[0].id
  instance_type = var.dns_instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.dns_server[0].id]
  subnet_id              = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.dns_server[0].name

  # Root Volume
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  # User Data - Install and configure Bind9
  user_data = templatefile("${path.module}/user-data/bind9-setup.sh.tpl", {
    domain            = var.customer_domain
    primary_ip        = var.primary_server_ip
    backup_bucket     = var.backup_bucket
    region            = data.aws_region.current.name
  })

  # IMDSv2 required
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name          = "${var.customer_domain}-dns-server"
    Domain        = var.customer_domain
    Type          = "DNS-Server"
    Service       = "Bind9"
    Environment   = var.environment
    ManagedBy     = "Terraform"
  }
}

# ==========================================
# ELASTIC IP FOR DNS SERVER
# ==========================================

resource "aws_eip" "dns_primary" {
  count    = var.enable_custom_dns ? 1 : 0
  domain   = "vpc"
  instance = aws_instance.dns_server[0].id

  tags = {
    Name        = "${var.customer_domain}-dns-primary-ip"
    Domain      = var.customer_domain
    Type        = "DNS"
    Environment = var.environment
  }
}

resource "aws_eip" "dns_secondary" {
  count  = var.enable_custom_dns && var.enable_secondary_dns ? 1 : 0
  domain = "vpc"

  tags = {
    Name        = "${var.customer_domain}-dns-secondary-ip"
    Domain      = var.customer_domain
    Type        = "DNS-Secondary"
    Environment = var.environment
  }
}

# ==========================================
# SECURITY GROUP FOR DNS SERVER
# ==========================================

resource "aws_security_group" "dns_server" {
  count       = var.enable_custom_dns ? 1 : 0
  name_prefix = "${var.customer_domain}-dns-sg-"
  description = "Security group for Bind9 DNS server"
  vpc_id      = var.vpc_id

  # DNS UDP Port 53
  ingress {
    description = "DNS queries (UDP)"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DNS TCP Port 53 (for zone transfers and large queries)
  ingress {
    description = "DNS queries (TCP)"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH for management
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
  }

  # Egress - all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.customer_domain}-dns-sg"
    Domain      = var.customer_domain
    Environment = var.environment
  }
}

# ==========================================
# IAM ROLE FOR DNS SERVER
# ==========================================

resource "aws_iam_role" "dns_server" {
  count       = var.enable_custom_dns ? 1 : 0
  name_prefix = "${var.customer_domain}-dns-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.customer_domain}-dns-role"
  }
}

# SSM Policy for remote management
resource "aws_iam_role_policy_attachment" "dns_ssm" {
  count      = var.enable_custom_dns ? 1 : 0
  role       = aws_iam_role.dns_server[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Policy
resource "aws_iam_role_policy_attachment" "dns_cloudwatch" {
  count      = var.enable_custom_dns ? 1 : 0
  role       = aws_iam_role.dns_server[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# S3 Backup Policy
resource "aws_iam_policy" "dns_s3_backup" {
  count       = var.enable_custom_dns ? 1 : 0
  name_prefix = "${var.customer_domain}-dns-s3-"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::${var.backup_bucket}",
        "arn:aws:s3:::${var.backup_bucket}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dns_s3_backup" {
  count      = var.enable_custom_dns ? 1 : 0
  role       = aws_iam_role.dns_server[0].name
  policy_arn = aws_iam_policy.dns_s3_backup[0].arn
}

# Instance Profile
resource "aws_iam_instance_profile" "dns_server" {
  count       = var.enable_custom_dns ? 1 : 0
  name_prefix = "${var.customer_domain}-dns-profile-"
  role        = aws_iam_role.dns_server[0].name
}

# ==========================================
# AMI DATA SOURCE
# ==========================================

data "aws_ami" "dns_server" {
  count       = var.enable_custom_dns ? 1 : 0
  most_recent = true
  owners      = ["679593333241"] # AlmaLinux

  filter {
    name   = "name"
    values = ["AlmaLinux OS 8*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_region" "current" {}

# ==========================================
# CLOUDWATCH ALARMS FOR DNS
# ==========================================

resource "aws_cloudwatch_metric_alarm" "dns_cpu" {
  count               = var.enable_custom_dns ? 1 : 0
  alarm_name          = "${var.customer_domain}-dns-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    InstanceId = aws_instance.dns_server[0].id
  }

  tags = {
    Name   = "${var.customer_domain}-dns-alarm"
    Domain = var.customer_domain
  }
}

resource "aws_cloudwatch_metric_alarm" "dns_status" {
  count               = var.enable_custom_dns ? 1 : 0
  alarm_name          = "${var.customer_domain}-dns-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "0"

  dimensions = {
    InstanceId = aws_instance.dns_server[0].id
  }

  tags = {
    Name   = "${var.customer_domain}-dns-status-alarm"
    Domain = var.customer_domain
  }
}
