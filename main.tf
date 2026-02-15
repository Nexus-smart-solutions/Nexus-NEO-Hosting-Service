# ================================================================
# NEO VPS - Main Configuration
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
# PROVIDER
# ================================================================

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "NEO-VPS"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# ================================================================
# NETWORK MODULE
# ================================================================

module "network" {
  source = "./modules/network"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  
  tags = var.tags
}

# ================================================================
# SECURITY MODULE
# ================================================================

module "security" {
  source = "./modules/security"
  
  vpc_id       = module.network.vpc_id
  project_name = var.project_name
  environment  = var.environment
  
  tags = var.tags
}

# ================================================================
# ROUTE53 MODULE
# ================================================================

module "route53" {
  source = "./modules/route53"
  
  customer_id = var.customer_id
  domain      = var.customer_domain
  server_ip   = var.server_ip
  
  # Custom Nameservers
  enable_custom_nameservers = var.enable_custom_nameservers
  ns1_ip                    = var.ns1_ip
  ns2_ip                    = var.ns2_ip
  
  # Additional Nameservers
  enable_additional_nameservers = var.enable_additional_nameservers
  ns3_ip                        = var.ns3_ip
  ns4_ip                        = var.ns4_ip
  
  # Mail Configuration
  enable_mail_records = var.enable_mail_records
  mail_server_ip      = var.mail_server_ip
  
  # Panel Configuration
  panel_type = var.control_panel
  
  # Environment
  environment = var.environment
  
  tags = var.tags
}

# ================================================================
# PANEL SERVER MODULE (Optional)
# ================================================================

module "panel_server" {
  source = "./modules/panel-server"
  count  = var.deploy_server ? 1 : 0
  
  subnet_id         = module.network.public_subnet_ids[0]
  security_group_id = module.security.panel_server_sg_id
  
  customer_id   = var.customer_id
  domain        = var.customer_domain
  control_panel = var.control_panel
  instance_type = var.instance_type
  
  key_name = var.ssh_key_name
  
  tags = var.tags
}
