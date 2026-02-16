#!/bin/bash

# ===================================
# AUTOMATED CUSTOMER PROVISIONING
# ===================================
# This script automatically provisions a complete cPanel hosting
# infrastructure for a new customer

set -euo pipefail

# ===================================
# COLORS FOR OUTPUT
# ===================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ===================================
# HELPER FUNCTIONS
# ===================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ===================================
# USAGE FUNCTION
# ===================================

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Automatically provision cPanel hosting infrastructure for a new customer.

Required Options:
    -d, --domain DOMAIN          Customer domain name (e.g., example.com)
    -e, --email EMAIL            Customer email address

Optional Options:
    -t, --instance-type TYPE     EC2 instance type (default: t3.medium)
    -s, --storage SIZE           Data volume size in GB (default: 100)
    -p, --plan PLAN              Hosting plan (basic|standard|premium, default: standard)
    -r, --region REGION          AWS region (default: us-east-1)
    --ssh-ip IP                  IP address allowed for SSH (CIDR format)
    --admin-ip IP                IP address allowed for admin panels (CIDR format)
    --dry-run                    Show what would be created without actually creating it
    -h, --help                   Show this help message

Examples:
    # Basic provisioning
    $0 -d customer.com -e customer@example.com

    # Premium plan with custom storage
    $0 -d customer.com -e customer@example.com -p premium -s 200

    # With restricted admin access
    $0 -d customer.com -e customer@example.com --admin-ip "203.0.113.0/24"

    # Dry run to see what would be created
    $0 -d customer.com -e customer@example.com --dry-run

EOF
    exit 1
}

# ===================================
# DEFAULT VALUES
# ===================================

INSTANCE_TYPE="t3.medium"
STORAGE_SIZE="100"
PLAN="standard"
REGION="us-east-1"
SSH_IP=""
ADMIN_IP=""
DRY_RUN=false
DOMAIN=""
EMAIL=""

# ===================================
# PARSE ARGUMENTS
# ===================================

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -e|--email)
            EMAIL="$2"
            shift 2
            ;;
        -t|--instance-type)
            INSTANCE_TYPE="$2"
            shift 2
            ;;
        -s|--storage)
            STORAGE_SIZE="$2"
            shift 2
            ;;
        -p|--plan)
            PLAN="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        --ssh-ip)
            SSH_IP="$2"
            shift 2
            ;;
        --admin-ip)
            ADMIN_IP="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# ===================================
# VALIDATION
# ===================================

if [[ -z "$DOMAIN" ]]; then
    log_error "Domain is required"
    usage
fi

if [[ -z "$EMAIL" ]]; then
    log_error "Email is required"
    usage
fi

# Validate email format
if ! [[ "$EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$ ]]; then
    log_error "Invalid email format: $EMAIL"
    exit 1
fi

# Validate domain format
if ! [[ "$DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
    log_error "Invalid domain format: $DOMAIN"
    exit 1
fi

# Validate plan
if ! [[ "$PLAN" =~ ^(basic|standard|premium)$ ]]; then
    log_error "Invalid plan: $PLAN (must be basic, standard, or premium)"
    exit 1
fi

# ===================================
# CONFIGURATION
# ===================================

# Convert domain to directory-safe name
CUSTOMER_DIR=$(echo "$DOMAIN" | tr '.' '-')
CUSTOMER_PATH="environments/customers/$CUSTOMER_DIR"

# Backend configuration (should match backend/outputs.tf)
BACKEND_BUCKET=$(cd backend && terraform output -raw state_bucket_name 2>/dev/null || echo "")
BACKEND_TABLE=$(cd backend && terraform output -raw lock_table_name 2>/dev/null || echo "")

if [[ -z "$BACKEND_BUCKET" ]] || [[ -z "$BACKEND_TABLE" ]]; then
    log_error "Backend infrastructure not found. Please run 'cd backend && terraform apply' first."
    exit 1
fi

# ===================================
# DISPLAY CONFIGURATION
# ===================================

log_info "==================================="
log_info "Customer Provisioning Configuration"
log_info "==================================="
echo ""
echo "Customer Details:"
echo "  Domain:       $DOMAIN"
echo "  Email:        $EMAIL"
echo "  Plan:         $PLAN"
echo ""
echo "Infrastructure:"
echo "  Instance:     $INSTANCE_TYPE"
echo "  Storage:      ${STORAGE_SIZE}GB"
echo "  Region:       $REGION"
echo ""
echo "Access Control:"
echo "  SSH IP:       ${SSH_IP:-None (use AWS SSM)}"
echo "  Admin IP:     ${ADMIN_IP:-None (use AWS SSM)}"
echo ""
echo "Backend:"
echo "  S3 Bucket:    $BACKEND_BUCKET"
echo "  DynamoDB:     $BACKEND_TABLE"
echo "  State Path:   customers/$CUSTOMER_DIR/terraform.tfstate"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    log_warning "DRY RUN MODE - No resources will be created"
    echo ""
fi

# ===================================
# CONFIRMATION
# ===================================

if [[ "$DRY_RUN" == false ]]; then
    read -p "Proceed with provisioning? (yes/no): " CONFIRM
    if [[ "$CONFIRM" != "yes" ]]; then
        log_info "Provisioning cancelled"
        exit 0
    fi
fi

# ===================================
# CREATE DIRECTORY STRUCTURE
# ===================================

log_info "Creating directory structure..."

if [[ -d "$CUSTOMER_PATH" ]]; then
    log_error "Customer directory already exists: $CUSTOMER_PATH"
    log_error "This customer may already be provisioned. Use a different domain or remove the existing directory."
    exit 1
fi

if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$CUSTOMER_PATH"
    log_success "Directory created: $CUSTOMER_PATH"
fi

# ===================================
# GENERATE TERRAFORM FILES
# ===================================

log_info "Generating Terraform configuration..."

# Backend configuration
cat > "$CUSTOMER_PATH/backend.tf" << EOF
# ===================================
# TERRAFORM BACKEND CONFIGURATION
# ===================================

terraform {
  backend "s3" {
    bucket         = "$BACKEND_BUCKET"
    key            = "customers/$CUSTOMER_DIR/terraform.tfstate"
    region         = "$REGION"
    dynamodb_table = "$BACKEND_TABLE"
    encrypt        = true
  }
}
EOF

# Main configuration
cat > "$CUSTOMER_PATH/main.tf" << EOF
# ===================================
# CUSTOMER: $DOMAIN
# ===================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Customer   = var.customer_domain
      Plan       = var.plan_type
      ManagedBy  = "Terraform"
      Email      = var.admin_email
      CreatedAt  = timestamp()
    }
  }
}

# ===================================
# NETWORK MODULE
# ===================================

module "network" {
  source = "../../modules/network"

  customer_domain = var.customer_domain
  environment     = var.environment
  region          = var.region
  vpc_cidr        = var.vpc_cidr

  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs

  enable_nat_gateway  = var.enable_nat_gateway
  enable_flow_logs    = var.enable_flow_logs
  enable_s3_endpoint  = var.enable_s3_endpoint

  tags = {
    Module = "Network"
  }
}

# ===================================
# SECURITY MODULE
# ===================================

module "security" {
  source = "../../modules/security"

  vpc_id              = module.network.vpc_id
  customer_domain     = var.customer_domain
  environment         = var.environment
  allowed_ssh_cidrs   = var.allowed_ssh_cidrs
  allowed_admin_cidrs = var.allowed_admin_cidrs

  tags = {
    Module = "Security"
  }
}

# ===================================
# CPANEL SERVER MODULE
# ===================================

module "cpanel_server" {
  source = "../../modules/cpanel-server"

  customer_domain = var.customer_domain
  environment     = var.environment
  region          = var.region

  vpc_id            = module.network.vpc_id
  subnet_id         = module.network.public_subnet_ids[0]
  security_group_id = module.security.cpanel_security_group_id

  instance_type       = var.instance_type
  root_volume_size    = var.root_volume_size
  root_volume_type    = var.root_volume_type
  data_volume_size    = var.data_volume_size
  data_volume_type    = var.data_volume_type

  cpanel_hostname             = var.cpanel_hostname
  admin_email                 = var.admin_email
  enable_backups              = var.enable_backups
  backup_retention_days       = var.backup_retention_days
  enable_detailed_monitoring  = var.enable_detailed_monitoring

  plan_type = var.plan_type

  tags = {
    Module = "cPanel-Server"
  }
}
EOF

# Variables file
cat > "$CUSTOMER_PATH/variables.tf" << EOF
# ===================================
# CUSTOMER VARIABLES
# ===================================

variable "customer_domain" {
  description = "Customer domain name"
  type        = string
  default     = "$DOMAIN"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "production"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "$REGION"
}

variable "plan_type" {
  description = "Hosting plan type"
  type        = string
  default     = "$PLAN"
}

# Network Variables
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["${REGION}a", "${REGION}b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "enable_s3_endpoint" {
  description = "Enable S3 VPC Endpoint"
  type        = bool
  default     = true
}

# Security Variables
variable "allowed_ssh_cidrs" {
  description = "Allowed SSH CIDRs"
  type        = list(string)
  default     = [${SSH_IP:+"\"$SSH_IP\""}]
}

variable "allowed_admin_cidrs" {
  description = "Allowed admin CIDRs"
  type        = list(string)
  default     = [${ADMIN_IP:+"\"$ADMIN_IP\""}]
}

# Server Variables
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "$INSTANCE_TYPE"
}

variable "root_volume_size" {
  description = "Root volume size (GB)"
  type        = number
  default     = 50
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}

variable "data_volume_size" {
  description = "Data volume size (GB)"
  type        = number
  default     = $STORAGE_SIZE
}

variable "data_volume_type" {
  description = "Data volume type"
  type        = string
  default     = "gp3"
}

variable "cpanel_hostname" {
  description = "cPanel hostname"
  type        = string
  default     = "cpanel.$DOMAIN"
}

variable "admin_email" {
  description = "Administrator email"
  type        = string
  default     = "$EMAIL"
}

variable "enable_backups" {
  description = "Enable backups"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention (days)"
  type        = number
  default     = 30
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = false
}
EOF

# Outputs file
cat > "$CUSTOMER_PATH/outputs.tf" << EOF
# ===================================
# CUSTOMER OUTPUTS
# ===================================

output "customer_domain" {
  description = "Customer domain"
  value       = var.customer_domain
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "server_public_ip" {
  description = "Server public IP"
  value       = module.cpanel_server.public_ip
}

output "nameservers" {
  description = "Nameservers"
  value       = [
    "ns1.\${var.customer_domain}",
    "ns2.\${var.customer_domain}"
  ]
}

output "access_urls" {
  description = "Access URLs"
  value = {
    whm     = "https://\${module.cpanel_server.public_ip}:2087"
    cpanel  = "https://\${module.cpanel_server.public_ip}:2083"
    webmail = "https://\${module.cpanel_server.public_ip}:2096"
  }
}

output "next_steps" {
  description = "Next steps for customer"
  value = <<-EOT
  
  ✅ Infrastructure provisioned successfully!
  
  Next Steps:
  1. Update DNS records for ${DOMAIN}:
     - Point ${DOMAIN} A record to \${module.cpanel_server.public_ip}
     - Create ns1.${DOMAIN} A record pointing to \${module.cpanel_server.public_ip}
     - Create ns2.${DOMAIN} A record pointing to \${module.cpanel_server.public_ip}
  
  2. SSH to server and install cPanel:
     ssh root@\${module.cpanel_server.public_ip}
     cd /home && curl -o latest -L https://securedownloads.cpanel.net/latest
     sh latest
  
  3. Access WHM: https://\${module.cpanel_server.public_ip}:2087
  
  4. Configure:
     - Enter cPanel license
     - Set up nameservers
     - Configure mail server
     - Enable AutoSSL
  
  EOT
}
EOF

log_success "Terraform configuration generated"

# ===================================
# TERRAFORM EXECUTION
# ===================================

if [[ "$DRY_RUN" == false ]]; then
    log_info "Initializing Terraform..."
    cd "$CUSTOMER_PATH"
    
    terraform init
    
    log_info "Planning deployment..."
    terraform plan -out=tfplan
    
    log_info "Applying deployment..."
    terraform apply tfplan
    
    rm -f tfplan
    
    log_success "Infrastructure deployed successfully!"
    
    # Display outputs
    terraform output
    
    cd - > /dev/null
else
    log_warning "Dry run complete. Files created in: $CUSTOMER_PATH"
    log_warning "Run without --dry-run to actually provision infrastructure"
fi

# ===================================
# COMPLETION
# ===================================

echo ""
log_success "======================================"
log_success "Customer Provisioning Complete!"
log_success "======================================"
echo ""
echo "Customer: $DOMAIN"
echo "Email:    $EMAIL"
echo "Plan:     $PLAN"
echo "Path:     $CUSTOMER_PATH"
echo ""

if [[ "$DRY_RUN" == false ]]; then
    log_info "Send welcome email:"
    echo "python3 automation/send-credentials.py \\"
    echo "  --domain $DOMAIN \\"
    echo "  --email $EMAIL \\"
    echo "  --outputs $CUSTOMER_PATH/terraform.tfstate"
fi

echo ""

# ==========================================
# Integration with provision-customer.sh
# Get server IP
# ==========================================

SERVER_IP=$(terraform output -raw elastic_ip)

# Run health check
if ./scripts/health-checks/check-provisioning.sh "$DOMAIN" "$PANEL" "$SERVER_IP"; then
  echo "✅ Server ready!"
  # Send success email
else
  echo "❌ Health check failed!"
  # Trigger rollback
  ./scripts/health-checks/rollback-failed.sh "$DOMAIN"
  exit 1
fi
