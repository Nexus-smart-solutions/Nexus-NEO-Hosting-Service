#!/bin/bash
# ===================================
# AUTOMATED CUSTOMER PROVISIONING
# ===================================
# This script provisions a new cPanel hosting account automatically
# Triggered after payment completion

set -e

# ===================================
# CONFIGURATION
# ===================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CUSTOMERS_DIR="$PROJECT_ROOT/environments/customers"

# Backend configuration (set these from backend setup)
STATE_BUCKET="${TF_BACKEND_BUCKET:-hosting-company-terraform-state}"
STATE_REGION="${TF_BACKEND_REGION:-us-east-1}"
LOCK_TABLE="${TF_LOCK_TABLE:-hosting-company-terraform-lock}"

# ===================================
# FUNCTIONS
# ===================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[ERROR] $*" >&2
    exit 1
}

validate_domain() {
    local domain=$1
    if [[ ! $domain =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*$ ]]; then
        error "Invalid domain name: $domain"
    fi
}

sanitize_domain() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr '.' '-'
}

# ===================================
# PARSE ARGUMENTS
# ===================================

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Provision a new cPanel hosting account

Required Options:
    -d, --domain DOMAIN          Customer domain name (e.g., customer.com)
    -e, --email EMAIL            Customer email address
    
Optional Options:
    -i, --instance-type TYPE     EC2 instance type (default: t3.medium)
    -s, --storage SIZE           Data volume size in GB (default: 100)
    -r, --region REGION          AWS region (default: us-east-1)
    -p, --plan PLAN              Hosting plan (basic|standard|premium)
    --skip-email                 Skip sending welcome email
    --dry-run                    Show what would be done without doing it
    -h, --help                   Show this help message

Examples:
    # Basic provisioning
    $0 -d customer.com -e customer@example.com
    
    # With custom settings
    $0 -d customer.com -e customer@example.com -i t3.large -s 200 -p premium
    
    # Dry run
    $0 -d customer.com -e customer@example.com --dry-run
EOF
    exit 1
}

# Default values
DOMAIN=""
EMAIL=""
INSTANCE_TYPE="t3.medium"
STORAGE_SIZE="100"
AWS_REGION="us-east-1"
HOSTING_PLAN="basic"
SKIP_EMAIL=false
DRY_RUN=false

# Parse arguments
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
        -i|--instance-type)
            INSTANCE_TYPE="$2"
            shift 2
            ;;
        -s|--storage)
            STORAGE_SIZE="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -p|--plan)
            HOSTING_PLAN="$2"
            shift 2
            ;;
        --skip-email)
            SKIP_EMAIL=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Validate required arguments
[[ -z "$DOMAIN" ]] && error "Domain is required. Use -d or --domain"
[[ -z "$EMAIL" ]] && error "Email is required. Use -e or --email"

validate_domain "$DOMAIN"

# ===================================
# SETUP CUSTOMER DIRECTORY
# ===================================

SANITIZED_DOMAIN=$(sanitize_domain "$DOMAIN")
CUSTOMER_DIR="$CUSTOMERS_DIR/$SANITIZED_DOMAIN"

log "=========================================="
log "Provisioning cPanel Hosting"
log "=========================================="
log "Domain: $DOMAIN"
log "Email: $EMAIL"
log "Instance Type: $INSTANCE_TYPE"
log "Storage: ${STORAGE_SIZE}GB"
log "Region: $AWS_REGION"
log "Plan: $HOSTING_PLAN"
log "Customer Directory: $CUSTOMER_DIR"
log "=========================================="

if [[ "$DRY_RUN" == "true" ]]; then
    log "DRY RUN MODE - No changes will be made"
    log "Would create: $CUSTOMER_DIR"
    exit 0
fi

# Create customer directory
if [ -d "$CUSTOMER_DIR" ]; then
    error "Customer directory already exists: $CUSTOMER_DIR"
fi

mkdir -p "$CUSTOMER_DIR"
log "Created customer directory: $CUSTOMER_DIR"

# ===================================
# GENERATE TERRAFORM CONFIGURATION
# ===================================

log "Generating Terraform configuration..."

# Generate backend.tf
cat > "$CUSTOMER_DIR/backend.tf" << EOF
terraform {
  backend "s3" {
    bucket         = "$STATE_BUCKET"
    key            = "customers/$SANITIZED_DOMAIN/terraform.tfstate"
    region         = "$STATE_REGION"
    dynamodb_table = "$LOCK_TABLE"
    encrypt        = true
  }
}
EOF

# Generate main.tf
cat > "$CUSTOMER_DIR/main.tf" << 'EOF'
# ===================================
# CUSTOMER CPANEL INFRASTRUCTURE
# ===================================

module "network" {
  source = "../../modules/network"

  customer_domain = var.customer_domain
  environment     = var.environment
  vpc_cidr        = var.vpc_cidr

  tags = var.tags
}

module "security" {
  source = "../../modules/security"

  vpc_id              = module.network.vpc_id
  customer_domain     = var.customer_domain
  environment         = var.environment
  allowed_ssh_cidrs   = var.allowed_ssh_cidrs
  allowed_admin_cidrs = var.allowed_admin_cidrs

  tags = var.tags
}

module "cpanel_server" {
  source = "../../modules/cpanel-server"

  customer_domain       = var.customer_domain
  environment           = var.environment
  vpc_id                = module.network.vpc_id
  subnet_id             = module.network.public_subnet_ids[0]
  security_group_id     = module.security.cpanel_security_group_id
  instance_type         = var.instance_type
  root_volume_size      = var.root_volume_size
  data_volume_size      = var.data_volume_size
  enable_backups        = var.enable_backups
  backup_retention_days = var.backup_retention_days
  admin_email           = var.admin_email

  tags = var.tags
}
EOF

# Generate variables.tf
cat > "$CUSTOMER_DIR/variables.tf" << 'EOF'
variable "customer_domain" {
  description = "Customer domain name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 50
}

variable "data_volume_size" {
  description = "Data volume size in GB"
  type        = number
}

variable "enable_backups" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention in days"
  type        = number
  default     = 30
}

variable "admin_email" {
  description = "Admin email for notifications"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed for SSH"
  type        = list(string)
  default     = []
}

variable "allowed_admin_cidrs" {
  description = "CIDR blocks allowed for admin access"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
EOF

# Generate terraform.tfvars
cat > "$CUSTOMER_DIR/terraform.tfvars" << EOF
customer_domain       = "cpanel.$DOMAIN"
environment           = "production"
instance_type         = "$INSTANCE_TYPE"
data_volume_size      = $STORAGE_SIZE
admin_email           = "$EMAIL"
allowed_ssh_cidrs     = []
allowed_admin_cidrs   = []

tags = {
  Customer     = "$DOMAIN"
  Email        = "$EMAIL"
  HostingPlan  = "$HOSTING_PLAN"
  ProvisionedAt = "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# Generate outputs.tf
cat > "$CUSTOMER_DIR/outputs.tf" << 'EOF'
output "customer_domain" {
  value = var.customer_domain
}

output "server_ip" {
  value = module.cpanel_server.elastic_ip
}

output "whm_url" {
  value = module.cpanel_server.whm_url
}

output "cpanel_url" {
  value = module.cpanel_server.cpanel_url
}

output "webmail_url" {
  value = module.cpanel_server.webmail_url
}

output "nameservers" {
  value = module.cpanel_server.nameservers
}

output "backup_bucket" {
  value = module.cpanel_server.backup_bucket_name
}
EOF

# Generate provider.tf
cat > "$CUSTOMER_DIR/provider.tf" << EOF
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
  region = "$AWS_REGION"
}
EOF

log "Terraform configuration generated successfully"

# ===================================
# TERRAFORM DEPLOYMENT
# ===================================

log "Initializing Terraform..."
cd "$CUSTOMER_DIR"
terraform init

log "Validating configuration..."
terraform validate

log "Planning deployment..."
terraform plan -out=tfplan

log "Applying deployment..."
terraform apply tfplan

log "Extracting outputs..."
terraform output -json > outputs.json

# ===================================
# SEND WELCOME EMAIL
# ===================================

if [[ "$SKIP_EMAIL" == "false" ]]; then
    log "Sending welcome email to $EMAIL..."
    python3 "$SCRIPT_DIR/send-credentials.py" \
        --domain "$DOMAIN" \
        --email "$EMAIL" \
        --outputs "$CUSTOMER_DIR/outputs.json"
fi

# ===================================
# COMPLETION
# ===================================

log "=========================================="
log "Provisioning completed successfully!"
log "=========================================="
log "Customer: $DOMAIN"
log "Server IP: $(terraform output -raw server_ip)"
log "WHM URL: $(terraform output -raw whm_url)"
log "=========================================="
log ""
log "Next steps:"
log "1. Configure DNS records (see outputs)"
log "2. Customer will receive welcome email with credentials"
log "3. Monitor deployment in AWS Console"
log ""
log "Customer directory: $CUSTOMER_DIR"
log "=========================================="

exit 0
