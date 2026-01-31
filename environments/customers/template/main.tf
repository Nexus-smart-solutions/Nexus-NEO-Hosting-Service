# ===================================
# MAIN CONFIGURATION
# ===================================
# Calls the infrastructure modules

terraform {
  required_version = ">= 1.0"
  
  # Backend configuration for state management
  backend "s3" {
    # Backend config will be provided via -backend-config flags
    encrypt = true
  }
}

# Network Module
module "network" {
  source = "../../../modules/network"
  
  customer_domain = var.customer_domain
  environment     = var.environment
  vpc_cidr        = var.vpc_cidr
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  
  enable_nat_gateway   = false
  enable_vpc_flow_logs = true
  
  tags = merge(
    var.tags,
    {
      Module = "network"
    }
  )
}

# Security Module
module "security" {
  source = "../../../modules/security"
  
  vpc_id          = module.network.vpc_id
  customer_domain = var.customer_domain
  environment     = var.environment
  
  # Don't allow SSH/Admin from anywhere - use SSM Session Manager
  allowed_ssh_cidrs   = []
  allowed_admin_cidrs = []
  
  tags = merge(
    var.tags,
    {
      Module = "security"
    }
  )
}

# cPanel Server Module
module "cpanel_server" {
  source = "../../../modules/cpanel-server"
  
  customer_domain   = var.customer_domain
  environment       = var.environment
  vpc_id            = module.network.vpc_id
  subnet_id         = module.network.public_subnet_ids[0]
  security_group_id = module.security.cpanel_security_group_id
  
  instance_type     = var.instance_type
  root_volume_size  = var.root_volume_size
  data_volume_size  = var.data_volume_size
  
  # Use customer_email for admin notifications
  admin_email = local.final_admin_email
  
  enable_backups        = var.enable_backups
  backup_retention_days = var.backup_retention_days
  enable_monitoring     = var.enable_monitoring
  
  tags = merge(
    var.tags,
    {
      Module   = "cpanel-server"
      ClientID = var.client_id
      Tier     = local.tier_name
    }
  )
}
