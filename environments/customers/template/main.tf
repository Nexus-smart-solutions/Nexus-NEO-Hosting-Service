# =================================================================
# MAIN INFRASTRUCTURE CONFIGURATION - NEXUS NEO HOSTING
# =================================================================

# 1. Route 53 Hosted Zone
resource "aws_route53_zone" "customer_zone" {
  name          = var.customer_domain
  force_destroy = false

  tags = {
    Name        = "Zone-${var.customer_domain}"
    Environment = var.environment
    ClientID    = var.client_id
  }
}

# 2. Domain Registration (Purchasing the domain)
resource "aws_route53domains_registered_domain" "domain_purchase" {
  domain_name = var.customer_domain

  admin_contact {
    first_name     = var.registrant_first_name
    last_name      = var.registrant_last_name
    address_line_1 = var.registrant_address
    city           = var.registrant_city
    country_code   = var.registrant_country_code
    email          = var.customer_email
    phone_number   = var.registrant_phone
    zip_code       = var.registrant_zip_code
  }

  registrant_contact {
    first_name     = var.registrant_first_name
    last_name      = var.registrant_last_name
    address_line_1 = var.registrant_address
    city           = var.registrant_city
    country_code   = var.registrant_country_code
    email          = var.customer_email
    phone_number   = var.registrant_phone
    zip_code       = var.registrant_zip_code
  }

  tech_contact {
    first_name     = "Nexus"
    last_name      = "Support"
    address_line_1 = "Nexus HQ"
    city           = "Dubai"
    country_code   = "AE"
    email          = "support@nexus-dxb.com"
    phone_number   = "+971.000000000"
    zip_code       = "00000"
  }

  auto_renew = true
}

# 3. EC2 Instance
resource "aws_instance" "hosting_server" {
  ami           = "ami-0fb653ca2d3203ac1" # Ubuntu in us-east-2
  instance_type = var.instance_type

  user_data = templatefile("${path.module}/environments/customers/template/scripts/ssl_setup.sh", {
    domain = var.customer_domain
    email  = var.customer_email
  })

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name      = "Server-${var.customer_domain}"
    ClientID  = var.client_id
    PlanTier  = var.plan_tier
  }
}

# 4. Elastic IP
resource "aws_eip" "server_ip" {
  instance = aws_instance.hosting_server.id
  domain   = "vpc"
}

# 5. DNS Records
resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.customer_zone.zone_id
  name    = var.customer_domain
  type    = "A"
  ttl     = "300"
  records = [aws_eip.server_ip.public_ip]
}

resource "aws_route53_record" "www_record" {
  zone_id = aws_route53_zone.customer_zone.zone_id
  name    = "www.${var.customer_domain}"
  type    = "CNAME"
  ttl     = "300"
  records = [var.customer_domain]
}

# 6. EBS Storage Volume
resource "aws_ebs_volume" "data_drive" {
  availability_zone = aws_instance.hosting_server.availability_zone
  size              = var.data_volume_size
  type              = "gp3"

  tags = {
    Name     = "Data-${var.customer_domain}"
    ClientID = var.client_id
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.data_drive.id
  instance_id = aws_instance.hosting_server.id
}
