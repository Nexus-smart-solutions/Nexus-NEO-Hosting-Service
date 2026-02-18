# ================================================================
# NEO VPS - Main Configuration
# ================================================================
# Multi-OS automated hosting provisioning
# ================================================================

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
  
  # Backend configuration (uncomment for production)
  # backend "s3" {
  #   bucket         = "neo-tf-state-ohio"
  #   key            = "global/terraform.tfstate"
  #   region         = "us-east-2"
  #   dynamodb_table = "neo-terraform-locks"
  #   encrypt        = true
  # }
}

# ================================================================
# PROVIDER
# ================================================================

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Neo-VPS"
      ManagedBy   = "Terraform"
      Environment = var.environment
      Repository  = "github.com/Nexus-smart-solutions/Nexus-NEO-Hosting-Service"
    }
  }
}

# ================================================================
# MODULES
# ================================================================

# Network Module
module "network" {
  source = "./modules/network"
  
  customer_domain = var.customer_domain
  vpc_cidr        = var.vpc_cidr
  environment     = var.environment
  
  tags = var.tags
}

# Security Module
module "security" {
  source = "./modules/security"
  
  vpc_id          = module.network.vpc_id
  customer_domain = var.customer_domain
  admin_cidrs     = var.admin_cidrs
  environment     = var.environment
  
  tags = var.tags
}

# Panel Server Module
module "panel_server" {
  source = "./modules/panel-server"
  
  customer_id       = var.customer_id
  customer_domain   = var.customer_domain
  customer_email    = var.customer_email
  os_type           = var.os_type
  control_panel     = var.control_panel
  instance_type     = var.instance_type
  root_volume_size  = var.root_volume_size
  data_volume_size  = var.data_volume_size
  
  vpc_id            = module.network.vpc_id
  subnet_id         = module.network.public_subnet_ids[0]
  security_group_id = module.security.panel_security_group_id
  
  ssh_key_name      = var.ssh_key_name
  environment       = var.environment
  
  tags = var.tags
  
  depends_on = [module.network, module.security]
}

# Route53 DNS Module (Optional)
module "route53" {
  count  = var.enable_route53 ? 1 : 0
  source = "./modules/route53"
  
  customer_id     = var.customer_id
  domain          = var.customer_domain
  server_ip       = module.panel_server.elastic_ip
  environment     = var.environment
  panel_type      = var.control_panel
  
  enable_mail_records       = var.enable_mail_records
  enable_custom_nameservers = var.enable_custom_nameservers
  ns1_ip                    = var.ns1_ip
  ns2_ip                    = var.ns2_ip
  
  tags = var.tags
  
  depends_on = [module.panel_server]
}
