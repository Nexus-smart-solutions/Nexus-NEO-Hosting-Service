# ===================================
# COMPLETE EXAMPLE - USING ALL 3 MODULES
# ===================================
# This shows how to deploy a complete cPanel hosting environment
# for a single customer using all three modules

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration (after backend setup)
  backend "s3" {
    bucket         = "hosting-company-terraform-state"
    key            = "customers/example-com/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "hosting-company-terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

# ===================================
# LOCAL VARIABLES
# ===================================

locals {
  customer_domain = "example.com"
  environment     = "production"
  
  common_tags = {
    Customer     = local.customer_domain
    Environment  = local.environment
    ManagedBy    = "Terraform"
    Project      = "cPanel-Hosting"
  }
}

# ===================================
# MODULE 1: NETWORK
# ===================================

module "network" {
  source = "../../modules/network"
  
  customer_domain = local.customer_domain
  environment     = local.environment
  
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24"]
  
  enable_nat_gateway   = false
  enable_vpc_flow_logs = true
  
  tags = local.common_tags
}

# ===================================
# MODULE 2: SECURITY
# ===================================

module "security" {
  source = "../../modules/security"
  
  vpc_id          = module.network.vpc_id
  customer_domain = local.customer_domain
  environment     = local.environment
  
  # Restrict admin access (recommended)
  allowed_ssh_cidrs   = []  # Use SSM Session Manager
  allowed_admin_cidrs = []  # Use SSM Session Manager
  
  # Or specify IPs:
  # allowed_ssh_cidrs   = ["203.0.113.10/32"]
  # allowed_admin_cidrs = ["203.0.113.10/32"]
  
  tags = local.common_tags
}

# ===================================
# MODULE 3: CPANEL SERVER
# ===================================

module "cpanel_server" {
  source = "../../modules/cpanel-server"
  
  customer_domain   = local.customer_domain
  environment       = local.environment
  vpc_id            = module.network.vpc_id
  subnet_id         = module.network.public_subnet_ids[0]
  security_group_id = module.security.cpanel_security_group_id
  
  # Server configuration
  instance_type    = "t3.medium"
  root_volume_size = 50
  data_volume_size = 100
  
  # Backup configuration
  enable_backups        = true
  backup_retention_days = 30
  
  # Monitoring
  enable_monitoring = true
  
  # Admin contact
  admin_email = "admin@example.com"
  
  tags = local.common_tags
}

# ===================================
# OUTPUTS
# ===================================

output "network_info" {
  description = "Network information"
  value = {
    vpc_id     = module.network.vpc_id
    vpc_cidr   = module.network.vpc_cidr
    subnet_ids = module.network.public_subnet_ids
  }
}

output "security_info" {
  description = "Security information"
  value = {
    security_group_id = module.security.cpanel_security_group_id
  }
}

output "server_info" {
  description = "Server access information"
  value = {
    instance_id  = module.cpanel_server.instance_id
    elastic_ip   = module.cpanel_server.elastic_ip
    whm_url      = module.cpanel_server.whm_url
    cpanel_url   = module.cpanel_server.cpanel_url
    webmail_url  = module.cpanel_server.webmail_url
    nameservers  = module.cpanel_server.nameservers
    ssh_command  = module.cpanel_server.ssh_command
  }
}

output "backup_info" {
  description = "Backup information"
  value = {
    bucket_name = module.cpanel_server.backup_bucket_name
  }
}

output "next_steps" {
  description = "What to do next"
  value = <<-EOT
    
    ========================================
    Deployment Complete!
    ========================================
    
    Customer: ${local.customer_domain}
    Server IP: ${module.cpanel_server.elastic_ip}
    
    NEXT STEPS:
    
    1. Configure DNS Records:
       cpanel.${local.customer_domain}    A    ${module.cpanel_server.elastic_ip}
       ns1.${local.customer_domain}       A    ${module.cpanel_server.elastic_ip}
       ns2.${local.customer_domain}       A    ${module.cpanel_server.elastic_ip}
    
    2. Request Reverse DNS from AWS:
       ${module.cpanel_server.elastic_ip}    PTR    cpanel.${local.customer_domain}
    
    3. Connect to server:
       ${module.cpanel_server.ssh_command}
    
    4. Install cPanel:
       sudo /root/install-cpanel.sh
    
    5. Access WHM:
       ${module.cpanel_server.whm_url}
    
    ========================================
  EOT
}
