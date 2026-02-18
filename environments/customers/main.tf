terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "network" {
  source       = "./modules/network"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
}

module "panel_server" {
  source = "./modules/panel-server"

  project_name    = var.project_name
  customer_id     = var.customer_id
  customer_domain = var.customer_domain
  control_panel   = var.control_panel

  subnet_id = module.network.public_subnet_id
  vpc_id    = module.network.vpc_id

  instance_type = var.instance_type
  allocate_eip  = true
}
