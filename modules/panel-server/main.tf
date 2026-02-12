# ===================================
# MULTI-PANEL SERVER MODULE - MAIN
# Neo VPS Provisioning System v2.0
# ===================================

locals {
  name_prefix = "${var.customer_domain}-${var.environment}"
  panel_hostname = var.panel_hostname != "" ? var.panel_hostname : "panel.${var.customer_domain}"
  
  # Panel-specific configurations
  panel_ports = {
    cyberpanel = {
      admin_port = 8090
      ssl_port   = 8090
    }
    cpanel = {
      admin_port = 2087
      ssl_port   = 2083
    }
    directadmin = {
      admin_port = 2222
      ssl_port   = 2222
    }
    none = {
      admin_port = 0
      ssl_port   = 0
    }
  }
}

# ===================================
# DATA SOURCES
# ===================================

# Get Golden AMI (clean AlmaLinux/Ubuntu)
data "aws_ami" "golden_ami" {
  count = var.use_custom_ami ? 0 : 1

  most_recent = true
  owners      = var.os_type == "almalinux" ? ["679593333241"] : ["099720109477"]

  filter {
    name = "name"
    values = var.os_type == "almalinux" ? [
      "AlmaLinux OS ${var.os_version}*"
    ] : [
      "ubuntu/images/hvm-ssd/ubuntu-*-${var.os_version}-amd64-server-*"
    ]
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

locals {
  ami_id = var.use_custom_ami ? var.custom_ami_id : data.aws_ami.golden_ami[0].id
}

# Get current AWS region and account
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ===================================
# IAM ROLE FOR EC2 INSTANCE
# ===================================

resource "aws_iam_role" "panel_server" {
  name_prefix = "${local.name_prefix}-panel-role-"

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
    Name        = "${local.name_prefix}-panel-role"
    Domain      = var.customer_domain
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "Neo-VPS"
  }
}

# SSM Access Policy
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.panel_server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Agent Policy
resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.panel_server.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# S3 Backup Policy
resource "aws_iam_policy" "s3_backup" {
  name_prefix = "${local.name_prefix}-s3-backup-"
  description = "Allow EC2 to write backups to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.backups.arn,
          "${aws_s3_bucket.backups.arn}/*"
        ]
      }
    ]
  })

  tags = {
    Name      = "${local.name_prefix}-s3-backup-policy"
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "s3_backup" {
  role       = aws_iam_role.panel_server.name
  policy_arn = aws_iam_policy.s3_backup.arn
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "panel_server" {
  name_prefix = "${local.name_prefix}-profile-"
  role        = aws_iam_role.panel_server.name

  tags = {
    Name      = "${local.name_prefix}-instance-profile"
    ManagedBy = "Terraform"
  }
}

# ===================================
# S3 BUCKET FOR BACKUPS
# ===================================

resource "aws_s3_bucket" "backups" {
  bucket_prefix = "${replace(var.customer_domain, ".", "-")}-backups-"

  tags = {
    Name        = "${var.customer_domain}-backups"
    Domain      = var.customer_domain
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "Neo-VPS"
  }
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

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
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

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket = aws_s3_bucket.backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ===================================
# EC2 KEY PAIR (if needed)
# ===================================

resource "aws_key_pair" "panel_server" {
  count = var.create_key_pair ? 1 : 0

  key_name_prefix = "${local.name_prefix}-key-"
  public_key      = var.public_key

  tags = {
    Name      = "${local.name_prefix}-key"
    Domain    = var.customer_domain
    ManagedBy = "Terraform"
  }
}

# ===================================
# EC2 INSTANCE
# ===================================

resource "aws_instance" "panel_server" {
  ami           = local.ami_id
  instance_type = var.instance_type
  key_name      = var.create_key_pair ? aws_key_pair.panel_server[0].key_name : var.existing_key_pair

  vpc_security_group_ids = [var.security_group_id]
  subnet_id              = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.panel_server.name

  # Root Volume
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${local.name_prefix}-root-volume"
    }
  }

  # User Data - Install selected control panel
  user_data = templatefile("${path.module}/user-data/${var.control_panel}.sh.tpl", {
    domain              = var.customer_domain
    panel_hostname      = local.panel_hostname
    backup_bucket       = aws_s3_bucket.backups.bucket
    region              = data.aws_region.current.name
    customer_email      = var.customer_email
    enable_monitoring   = var.enable_detailed_monitoring
    control_panel       = var.control_panel
  })

  # Enable detailed monitoring if requested
  monitoring = var.enable_detailed_monitoring

  # IMDSv2 required
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name            = "${local.name_prefix}-server"
    Domain          = var.customer_domain
    ControlPanel    = var.control_panel
    Customer        = var.customer_id
    Environment     = var.environment
    ManagedBy       = "Terraform"
    Project         = "Neo-VPS"
    BillingStatus   = "active"
  }

  lifecycle {
    ignore_changes = [
      user_data,  # Don't recreate on user_data changes
      ami         # Don't recreate on AMI updates
    ]
  }

  depends_on = [
    aws_s3_bucket.backups,
    aws_iam_instance_profile.panel_server
  ]
}

# ===================================
# DATA VOLUME (Separate EBS)
# ===================================

resource "aws_ebs_volume" "data" {
  availability_zone = aws_instance.panel_server.availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  encrypted         = true

  tags = {
    Name        = "${local.name_prefix}-data-volume"
    Domain      = var.customer_domain
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_volume_attachment" "data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.panel_server.id
}

# ===================================
# ELASTIC IP
# ===================================

resource "aws_eip" "panel_server" {
  count    = var.allocate_elastic_ip ? 1 : 0
  domain   = "vpc"
  instance = aws_instance.panel_server.id

  tags = {
    Name        = "${local.name_prefix}-eip"
    Domain      = var.customer_domain
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  depends_on = [aws_instance.panel_server]
}

# ===================================
# CLOUDWATCH ALARMS
# ===================================

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${local.name_prefix}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "CPU utilization exceeds 80%"

  dimensions = {
    InstanceId = aws_instance.panel_server.id
  }

  tags = {
    Name   = "${local.name_prefix}-cpu-alarm"
    Domain = var.customer_domain
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${local.name_prefix}-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Instance status check failed"

  dimensions = {
    InstanceId = aws_instance.panel_server.id
  }

  tags = {
    Name   = "${local.name_prefix}-status-alarm"
    Domain = var.customer_domain
  }
}

# ===================================
# SNAPSHOTS (Optional Daily Backup)
# ===================================

resource "aws_dlm_lifecycle_policy" "ebs_snapshots" {
  count              = var.enable_daily_snapshots ? 1 : 0
  description        = "Daily EBS snapshots for ${var.customer_domain}"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role[0].arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "Daily snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["03:00"]
      }

      retain_rule {
        count = var.snapshot_retention_days
      }

      tags_to_add = {
        SnapshotType = "DailyBackup"
        Domain       = var.customer_domain
      }

      copy_tags = true
    }

    target_tags = {
      Domain = var.customer_domain
    }
  }

  tags = {
    Name      = "${local.name_prefix}-snapshot-policy"
    ManagedBy = "Terraform"
  }
}

# IAM Role for DLM
resource "aws_iam_role" "dlm_lifecycle_role" {
  count = var.enable_daily_snapshots ? 1 : 0

  name_prefix = "${local.name_prefix}-dlm-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "dlm.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dlm_lifecycle" {
  count      = var.enable_daily_snapshots ? 1 : 0
  role       = aws_iam_role.dlm_lifecycle_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}
