# ===================================
# CPANEL SERVER MODULE - COMPLETE
# ===================================

# Data source for AlmaLinux AMI
data "aws_ami" "almalinux" {
  most_recent = true
  owners      = ["679593333241"]  # AlmaLinux official

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

# ===================================
# IAM ROLE FOR EC2 INSTANCE
# ===================================

resource "aws_iam_role" "cpanel_role" {
  name_prefix = "${var.customer_domain}-cpanel-role-"

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

  tags = merge(
    var.tags,
    {
      Name     = "${var.customer_domain}-cpanel-role"
      Customer = var.customer_domain
    }
  )
}

# Attach SSM policy for Session Manager
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.cpanel_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch policy
resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.cpanel_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom S3 backup policy
resource "aws_iam_role_policy" "s3_backup_policy" {
  name_prefix = "${var.customer_domain}-s3-backup-"
  role        = aws_iam_role.cpanel_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ]
      Resource = [
        aws_s3_bucket.backups.arn,
        "${aws_s3_bucket.backups.arn}/*"
      ]
    }]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "cpanel_profile" {
  name_prefix = "${var.customer_domain}-cpanel-profile-"
  role        = aws_iam_role.cpanel_role.name

  tags = var.tags
}

# ===================================
# EC2 INSTANCE
# ===================================

resource "aws_instance" "cpanel" {
  ami                  = data.aws_ami.almalinux.id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile = aws_iam_instance_profile.cpanel_profile.name
  
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = false
    encrypted             = true
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    hostname = "cpanel.${var.customer_domain}"
  }))

  monitoring = var.enable_monitoring

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
  
  tags = merge(
    var.tags,
    {
      Name     = "${var.customer_domain}-cpanel"
      Customer = var.customer_domain
      Role     = "cPanel-Server"
    }
  )

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

# ===================================
# ELASTIC IP
# ===================================

resource "aws_eip" "cpanel" {
  domain = "vpc"
  
  tags = merge(
    var.tags,
    {
      Name     = "${var.customer_domain}-eip"
      Customer = var.customer_domain
    }
  )
}

resource "aws_eip_association" "cpanel" {
  instance_id   = aws_instance.cpanel.id
  allocation_id = aws_eip.cpanel.id
}

# ===================================
# DATA VOLUME
# ===================================

resource "aws_ebs_volume" "data" {
  availability_zone = aws_instance.cpanel.availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  encrypted         = true
  iops              = 3000
  throughput        = 125
  
  tags = merge(
    var.tags,
    {
      Name     = "${var.customer_domain}-data-volume"
      Customer = var.customer_domain
    }
  )
}

resource "aws_volume_attachment" "data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.cpanel.id
}

# ===================================
# S3 BACKUP BUCKET
# ===================================

resource "aws_s3_bucket" "backups" {
  bucket_prefix = "${var.customer_domain}-backups-"
  
  tags = merge(
    var.tags,
    {
      Name     = "${var.customer_domain}-backups"
      Customer = var.customer_domain
      Purpose  = "cPanel-Backups"
    }
  )
}

# Enable versioning
resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "backups" {
  bucket = aws_s3_bucket.backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  count = var.enable_backups ? 1 : 0
  
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
