# =================================================================
# MAIN INFRASTRUCTURE CONFIGURATION - NEXUS NEO HOSTING
# Production-Ready Template for Multi-Tenant cPanel Hosting
# =================================================================

# =================================================================
# DATA SOURCES
# =================================================================

data "aws_ami" "almalinux" {
  most_recent = true
  owners      = ["679593333241"]
  
  filter {
    name   = "name"
    values = ["AlmaLinux OS 8*"]
  }
  
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# =================================================================
# NETWORKING
# =================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "VPC-${var.customer_domain}"
    Environment = var.environment
    ClientID    = var.client_id
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name     = "IGW-${var.customer_domain}"
    ClientID = var.client_id
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  
  tags = {
    Name     = "Public-Subnet-${var.customer_domain}"
    ClientID = var.client_id
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name     = "Public-RT-${var.customer_domain}"
    ClientID = var.client_id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# =================================================================
# SECURITY GROUPS
# =================================================================

resource "aws_security_group" "cpanel_server" {
  name        = "cpanel-server-${var.client_id}"
  description = "Security group for cPanel server"
  vpc_id      = aws_vpc.main.id
  
  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # WHM
  ingress {
    description = "WHM"
    from_port   = 2087
    to_port     = 2087
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # cPanel
  ingress {
    description = "cPanel"
    from_port   = 2083
    to_port     = 2083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Webmail
  ingress {
    description = "Webmail"
    from_port   = 2096
    to_port     = 2096
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # FTP
  ingress {
    description = "FTP"
    from_port   = 21
    to_port     = 21
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # FTP Passive Mode
  ingress {
    description = "FTP Passive"
    from_port   = 49152
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # SMTP
  ingress {
    description = "SMTP"
    from_port   = 25
    to_port     = 25
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # SMTP Submission
  ingress {
    description = "SMTP Submission"
    from_port   = 587
    to_port     = 587
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # POP3
  ingress {
    description = "POP3"
    from_port   = 110
    to_port     = 110
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # POP3S
  ingress {
    description = "POP3S"
    from_port   = 995
    to_port     = 995
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # IMAP
  ingress {
    description = "IMAP"
    from_port   = 143
    to_port     = 143
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # IMAPS
  ingress {
    description = "IMAPS"
    from_port   = 993
    to_port     = 993
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # DNS
  ingress {
    description = "DNS TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "DNS UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Outbound
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name     = "SG-cPanel-${var.customer_domain}"
    ClientID = var.client_id
  }
}

# =================================================================
# IAM ROLES & POLICIES
# =================================================================

resource "aws_iam_role" "instance_role" {
  name = "${var.client_id}-instance-role"
  
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
    Name     = "Role-${var.customer_domain}"
    ClientID = var.client_id
  }
}

resource "aws_iam_role_policy" "instance_policy" {
  name = "${var.client_id}-instance-policy"
  role = aws_iam_role.instance_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.backups.arn,
          "${aws_s3_bucket.backups.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.client_id}-instance-profile"
  role = aws_iam_role.instance_role.name
  
  tags = {
    Name     = "Profile-${var.customer_domain}"
    ClientID = var.client_id
  }
}

# =================================================================
# ROUTE 53 - DNS MANAGEMENT
# =================================================================

resource "aws_route53_zone" "customer_zone" {
  name          = var.customer_domain
  force_destroy = false
  
  tags = {
    Name        = "Zone-${var.customer_domain}"
    Environment = var.environment
    ClientID    = var.client_id
  }
}

resource "aws_route53domains_registered_domain" "domain_purchase" {
  count = var.auto_register_domain ? 1 : 0
  
  domain_name = var.customer_domain
  
  admin_contact {
    first_name     = local.final_admin_first_name
    last_name      = local.final_admin_last_name
    address_line_1 = var.registrant_address
    city           = var.registrant_city
    country_code   = var.registrant_country_code
    email          = local.final_admin_email
    phone_number   = local.final_admin_phone
    zip_code       = var.registrant_zip_code
  }
  
  registrant_contact {
    first_name     = var.registrant_first_name
    last_name      = var.registrant_last_name
    organization   = var.registrant_organization
    address_line_1 = var.registrant_address
    city           = var.registrant_city
    state          = var.registrant_state
    country_code   = var.registrant_country_code
    email          = local.final_registrant_email
    phone_number   = var.registrant_phone
    zip_code       = var.registrant_zip_code
  }
  
  tech_contact {
    first_name     = local.final_tech_first_name
    last_name      = local.final_tech_last_name
    address_line_1 = var.registrant_address
    city           = var.registrant_city
    country_code   = var.registrant_country_code
    email          = local.final_tech_email
    phone_number   = local.final_tech_phone
    zip_code       = var.registrant_zip_code
  }
  
  auto_renew = var.auto_renew_domain
  
  tags = {
    Name     = "Domain-${var.customer_domain}"
    ClientID = var.client_id
  }
}

# =================================================================
# EC2 INSTANCE - CPANEL SERVER
# =================================================================

resource "aws_instance" "hosting_server" {
  ami           = data.aws_ami.almalinux.id
  instance_type = var.instance_type
  
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.cpanel_server.id]
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name
  
  user_data = templatefile("${path.module}/scripts/ssl_setup.sh", {
    domain = var.customer_domain
    email  = var.customer_email
  })
  
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }
  
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  
  monitoring = var.enable_monitoring
  
  tags = {
    Name        = "Server-${var.customer_domain}"
    ClientID    = var.client_id
    PlanTier    = var.plan_tier
    Environment = var.environment
  }
  
  lifecycle {
    ignore_changes = [ami]
  }
}

# =================================================================
# ELASTIC IP
# =================================================================

resource "aws_eip" "server_ip" {
  domain   = "vpc"
  instance = aws_instance.hosting_server.id
  
  tags = {
    Name     = "EIP-${var.customer_domain}"
    ClientID = var.client_id
  }
  
  depends_on = [aws_internet_gateway.main]
}

# =================================================================
# DNS RECORDS
# =================================================================

resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.customer_zone.zone_id
  name    = var.customer_domain
  type    = "A"
  ttl     = 300
  records = [aws_eip.server_ip.public_ip]
}

resource "aws_route53_record" "www_record" {
  zone_id = aws_route53_zone.customer_zone.zone_id
  name    = "www.${var.customer_domain}"
  type    = "CNAME"
  ttl     = 300
  records = [var.customer_domain]
}

resource "aws_route53_record" "cpanel_record" {
  zone_id = aws_route53_zone.customer_zone.zone_id
  name    = "cpanel.${var.customer_domain}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.server_ip.public_ip]
}

resource "aws_route53_record" "mail_record" {
  zone_id = aws_route53_zone.customer_zone.zone_id
  name    = var.customer_domain
  type    = "MX"
  ttl     = 300
  records = ["0 mail.${var.customer_domain}"]
}

resource "aws_route53_record" "mail_a_record" {
  zone_id = aws_route53_zone.customer_zone.zone_id
  name    = "mail.${var.customer_domain}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.server_ip.public_ip]
}

# =================================================================
# EBS STORAGE VOLUME
# =================================================================

resource "aws_ebs_volume" "data_drive" {
  availability_zone = aws_instance.hosting_server.availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  encrypted         = true
  
  tags = {
    Name        = "Data-${var.customer_domain}"
    ClientID    = var.client_id
    Environment = var.environment
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.data_drive.id
  instance_id = aws_instance.hosting_server.id
}

# =================================================================
# S3 BACKUP BUCKET
# =================================================================

resource "aws_s3_bucket" "backups" {
  bucket = "${var.client_id}-backups-${random_string.bucket_suffix.result}"
  
  tags = {
    Name        = "Backups-${var.customer_domain}"
    ClientID    = var.client_id
    Environment = var.environment
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket = aws_s3_bucket.backups.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  count  = var.enable_backups ? 1 : 0
  bucket = aws_s3_bucket.backups.id
  
  rule {
    id     = "delete-old-backups"
    status = "Enabled"
    
    expiration {
      days = var.backup_retention_days
    }
    
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}
