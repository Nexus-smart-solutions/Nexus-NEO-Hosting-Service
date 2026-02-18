# ===================================
# NEO VPS PROVISIONING SYSTEM - MAIN
# ===================================

terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

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
  panel_type      = var.control_panel
  
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
  
  customer_id          = var.customer_id
  customer_domain      = var.customer_domain
  customer_email       = var.customer_email
  environment          = var.environment
  os_type              = var.os_type
  os_version           = var.os_version
  control_panel        = var.control_panel
  instance_type        = var.instance_type
  root_volume_size     = var.root_volume_size
  data_volume_size     = var.data_volume_size
  subnet_id            = module.network.public_subnet_ids[0]
  security_group_id    = module.security.panel_security_group_id
  create_key_pair      = var.create_key_pair
  public_key           = var.public_key
  existing_key_pair    = var.existing_key_pair
  backup_retention_days = var.backup_retention_days
  enable_detailed_monitoring = var.enable_detailed_monitoring
  enable_cloudwatch_alarms   = var.enable_cloudwatch_alarms
  enable_daily_snapshots     = var.enable_daily_snapshots
  snapshot_retention_days    = var.snapshot_retention_days
  allocate_elastic_ip        = var.allocate_eip
  use_custom_ami       = var.use_custom_ami
  custom_ami_id        = var.custom_ami_id
  panel_hostname       = var.panel_hostname

  depends_on = [module.network, module.security]
}

# ===================================
# ROUTE53 MODULE
# ===================================

module "route53" {
  count  = var.enable_route53 ? 1 : 0
  source = "./modules/route53"
  
  customer_id = var.customer_id
  domain      = var.customer_domain
  server_ip   = var.allocate_eip ? module.panel_server.elastic_ip : module.panel_server.private_ip
  environment = var.environment
  panel_type  = var.control_panel
  enable_mail_records       = var.enable_mail_records
  enable_custom_nameservers = var.enable_custom_nameservers
  ns1_ip                    = var.ns1_ip
  ns2_ip                    = var.ns2_ip
  alarm_actions = var.sns_topic_arn
  
  tags = {
    Customer = var.customer_id
    Domain   = var.customer_domain
  }
  
  depends_on = [module.panel_server]
}

# ===================================
# MONITORING MODULE - WITH CI/CD FIX
# ===================================

module "monitoring" {
  # Use different sources based on environment
  source = var.ci_cd ? "/home/runner/work/Nexus-NEO-Hosting-Service/Nexus-NEO-Hosting-Service/modules/monitoring" : "./modules/monitoring"
  
  customer_id      = var.customer_id
  customer_domain  = var.customer_domain
  instance_id      = module.panel_server.instance_id
  environment      = var.environment
  sns_topic_arn    = var.sns_topic_arn
  alert_email      = var.alert_email != "" ? var.alert_email : "dev@nexus-dxb.com"
  slack_webhook    = var.slack_webhook
  cpu_high_threshold      = var.cpu_high_threshold
  disk_threshold          = var.disk_threshold
  memory_threshold        = var.memory_threshold
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
