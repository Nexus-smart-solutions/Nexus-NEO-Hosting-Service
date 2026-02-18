# ===================================
# NEO VPS PROVISIONING SYSTEM - MAIN
# ===================================
# This configuration provisions a complete VPS hosting environment
# with support for multiple control panels (CyberPanel, cPanel, DirectAdmin)
# ===================================

terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Updated to 5.x for better compatibility
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  
  # Backend configuration (uncomment for production)
  # backend "s3" {
  #   bucket         = "neo-tf-state-ohio"
  #   key            = "neo-vps/terraform.tfstate"
  #   region         = "us-east-2"
  #   dynamodb_table = "neo-tf-locks"
  #   encrypt        = true
  # }
}

# ===================================
# PROVIDER CONFIGURATION
# ===================================

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Neo-VPS"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# ===================================
# DATA SOURCES
# ===================================

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# ===================================
# NETWORK MODULE
# ===================================

module "network" {
  source = "./modules/network"
  
  customer_domain = var.customer_domain
  vpc_cidr        = var.vpc_cidr
  environment     = var.environment
  
  # Optional: Specify AZs
  availability_zones = data.aws_availability_zones.available.names
  
  tags = {
    Customer = var.customer_id
    Domain   = var.customer_domain
  }
}

# ===================================
# SECURITY MODULE
# ===================================

module "security" {
  source = "./modules/security"
  
  vpc_id          = module.network.vpc_id
  customer_domain = var.customer_domain
  admin_cidrs     = var.admin_cidrs
  environment     = var.environment
  
  # Panel-specific ports
  panel_type = var.control_panel
  
  tags = {
    Customer = var.customer_id
    Domain   = var.customer_domain
  }
  
  depends_on = [module.network]
}

# ===================================
# PANEL SERVER MODULE
# ===================================

module "panel_server" {
  source = "./modules/panel-server"
  
  # Customer Information
  customer_id          = var.customer_id
  customer_domain      = var.customer_domain
  customer_email       = var.customer_email
  environment          = var.environment
  
  # Server Configuration
  os_type              = var.os_type
  os_version           = var.os_version
  control_panel        = var.control_panel
  instance_type        = var.instance_type
  root_volume_size     = var.root_volume_size
  data_volume_size     = var.data_volume_size
  
  # Networking
  subnet_id            = module.network.public_subnet_ids[0]
  security_group_id    = module.security.panel_security_group_id
  
  # Key Pair Configuration
  create_key_pair      = var.create_key_pair
  public_key           = var.public_key
  existing_key_pair    = var.existing_key_pair
  
  # Backup Settings
  backup_retention_days = var.backup_retention_days
  
  # Feature Flags
  enable_detailed_monitoring = var.enable_detailed_monitoring
  enable_cloudwatch_alarms   = var.enable_cloudwatch_alarms
  enable_daily_snapshots     = var.enable_daily_snapshots
  snapshot_retention_days    = var.snapshot_retention_days
  allocate_elastic_ip        = var.allocate_eip
  
  # AMI Options
  use_custom_ami       = var.use_custom_ami
  custom_ami_id        = var.custom_ami_id
  
  # Panel Hostname
  panel_hostname       = var.panel_hostname

  depends_on = [module.network, module.security]
}

# ===================================
# ROUTE53 MODULE (Optional)
# ===================================

module "route53" {
  count  = var.enable_route53 ? 1 : 0
  source = "./modules/route53"
  
  customer_id = var.customer_id
  domain      = var.customer_domain
  server_ip   = var.allocate_eip ? module.panel_server.elastic_ip : module.panel_server.private_ip
  environment = var.environment
  panel_type  = var.control_panel
  
  # DNS Records Configuration
  enable_mail_records       = var.enable_mail_records
  enable_custom_nameservers = var.enable_custom_nameservers
  ns1_ip                    = var.ns1_ip
  ns2_ip                    = var.ns2_ip
  
  # Alarm Actions (SNS Topic ARN)
  alarm_actions = var.sns_topic_arn
  
  tags = {
    Customer = var.customer_id
    Domain   = var.customer_domain
  }
  
  depends_on = [module.panel_server]
}

# ===================================
# MONITORING MODULE
# ===================================

module "monitoring" {
  source = "./modules/monitoring"
  
  customer_id      = var.customer_id
  customer_domain  = var.customer_domain
  instance_id      = module.panel_server.instance_id
  environment      = var.environment
  
  # SNS Configuration
  sns_topic_arn    = var.sns_topic_arn
  alert_email      = var.alert_email != "" ? var.alert_email : "dev@nexus-dxb.com"
  slack_webhook    = var.slack_webhook
  
  # Alarm Thresholds
  cpu_high_threshold      = var.cpu_high_threshold
  disk_threshold          = var.disk_threshold
  memory_threshold        = var.memory_threshold
  
  # Feature Flags
  enable_disk_alarm       = var.enable_disk_alarm
  enable_memory_alarm     = var.enable_memory_alarm
  create_dashboard        = var.create_dashboard
  create_dashboard_with_python = var.create_dashboard_with_python
  
  tags = {
    Customer = var.customer_id
    Domain   = var.customer_domain
  }
  
  depends_on = [module.panel_server]
}

# ===================================
# OUTPUTS
# ===================================

output "instance_id" {
  description = "ID of the panel server instance"
  value       = module.panel_server.instance_id
}

output "private_ip" {
  description = "Private IP of the panel server"
  value       = module.panel_server.private_ip
}

output "public_ip" {
  description = "Public IP (if Elastic IP allocated)"
  value       = var.allocate_eip ? module.panel_server.elastic_ip : null
}

output "panel_url" {
  description = "Panel admin URL"
  value       = var.allocate_eip ? "https://${var.control_panel != "none" ? module.panel_server.panel_hostname : ""}" : null
}

output "backup_bucket" {
  description = "S3 bucket name for backups"
  value       = module.panel_server.backup_bucket
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs"
  value       = module.network.public_subnet_ids
}

output "security_group_id" {
  description = "Security Group ID"
  value       = module.security.panel_security_group_id
}

output "route53_zone_id" {
  description = "Route53 Hosted Zone ID"
  value       = var.enable_route53 ? module.route53[0].zone_id : null
}

# Monitoring Outputs
output "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = module.monitoring.sns_topic_arn
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = module.monitoring.dashboard_name
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = module.monitoring.dashboard_url
}

output "alarm_names" {
  description = "Names of created CloudWatch alarms"
  value       = module.monitoring.alarm_names
}

output "connection_commands" {
  description = "Commands to connect to the server"
  value = <<-EOT
    # Connect to the server:
    ssh -i ${var.create_key_pair ? "~/path/to/private-key.pem" : var.existing_key_pair} ${var.os_type == "almalinux" ? "almalinux" : "ubuntu"}@${var.allocate_eip ? module.panel_server.elastic_ip : module.panel_server.private_ip}
    
    ${var.control_panel != "none" ? "# Panel URL: https://${module.panel_server.panel_hostname}" : ""}
    
    # Monitoring:
    ${var.create_dashboard ? "# Dashboard: ${module.monitoring.dashboard_url}" : ""}
  EOT
}

output "module_info" {
  description = "Information about the modules used"
  value = {
    network    = "modules/network"
    security   = "modules/security"
    panel      = "modules/panel-server"
    route53    = var.enable_route53 ? "modules/route53" : "disabled"
    monitoring = "modules/monitoring (enabled)"
  }
}
