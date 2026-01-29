# 🚀 Nexus NEO: Hosting Platform # 🚀

**Automated cPanel provisioning system with Terraform modules for multi-customer hosting**

## 📋 Overview

This is a production-ready, multi-tenant cPanel hosting platform that automatically provisions isolated hosting environments for customers. Built with Terraform modules, it supports:

- ✅ **Automated Provisioning**: Deploy new customer hosting in minutes
- ✅ **Multi-Tenant Architecture**: Isolated infrastructure per customer
- ✅ **Remote State Management**: Secure S3 backend with state locking
- ✅ **Modular Design**: Reusable network, security, and server modules
- ✅ **Email Automation**: Automatic welcome emails with credentials
- ✅ **Cost Optimization**: Pay only for what customers use

---

## 🏗️ Architecture

```
Platform Structure:
├── modules/                    # Reusable Terraform modules
│   ├── network/               # VPC, Subnets, IGW, NAT
│   ├── security/              # Security Groups (all cPanel ports)
│   └── cpanel-server/         # EC2, EBS, IAM, S3 backups
├── backend/                   # S3 + DynamoDB state backend
├── automation/                # Provisioning scripts
│   ├── provision-customer.sh  # Auto-provision new customers
│   └── send-credentials.py    # Email automation
└── environments/
    └── customers/             # Per-customer deployments
        ├── customer1-com/     # Isolated state files
        ├── customer2-com/
        └── ...
```

### Multi-Tenant Isolation

Each customer gets:
- ✅ Dedicated VPC
- ✅ Dedicated EC2 instance
- ✅ Dedicated EBS volumes
- ✅ Dedicated S3 backup bucket
- ✅ Separate Terraform state file
- ✅ Independent scaling

---

## 🚀 Quick Start

### Prerequisites

1. **AWS Account** with admin access
2. **AWS CLI** configured (`aws configure`)
3. **Terraform** >= 1.0 installed
4. **Python 3** with boto3 (`pip install boto3`)
5. **Domain registrar** access for DNS

### Step 1: Set up Backend Infrastructure

```bash
# One-time setup for S3 backend
cd backend
terraform init
terraform apply

# Save outputs
terraform output > backend-config.txt
```

This creates:
- S3 bucket for Terraform state
- DynamoDB table for state locking
- IAM policies for access

### Step 2: Provision First Customer

```bash
# Automatic provisioning
./automation/provision-customer.sh \
  --domain customer.com \
  --email customer@example.com \
  --instance-type t3.medium \
  --storage 100

# The script will:
# 1. Create customer directory
# 2. Generate Terraform config
# 3. Deploy infrastructure
# 4. Send a welcome email
```

### Step 3: Configure DNS

Point the customer's nameservers to:
```
ns1.customer.com → <SERVER_IP>
ns2.customer.com → <SERVER_IP>
```

### Step 4: Complete cPanel Setup

Customer receives email with:
- WHM URL and credentials
- cPanel access
- DNS settings
- Next steps

---

## 📦 Module Structure

### Network Module

**Location**: `modules/network/`

Creates per-customer VPC with:
- Public subnet (for cPanel server)
- Private subnet (optional)
- Internet Gateway
- NAT Gateway (optional)
- VPC Flow Logs

**Usage**:
```hcl
module "network" {
  source = "./modules/network"

  customer_domain = "customer.com"
  environment     = "production"
  vpc_cidr        = "10.0.0.0/16"
}
```

### Security Module

**Location**: `modules/security/`

Creates security groups with all cPanel ports:
- HTTP/HTTPS (80, 443)
- SSH (22)
- WHM (2087)
- cPanel (2083)
- Webmail (2096)
- FTP (21, 49152-65535)
- Email (25, 587, 110, 143, 993, 995)
- DNS (53)

**Usage**:
```hcl
module "security" {
  source = "./modules/security"

  vpc_id              = module.network.vpc_id
  customer_domain     = "customer.com"
  allowed_ssh_cidrs   = ["203.0.113.0/24"]
  allowed_admin_cidrs = ["203.0.113.0/24"]
}
```

### cPanel Server Module

**Location**: `modules/cpanel-server/`

Creates:
- EC2 instance (AlmaLinux 8)
- Elastic IP
- EBS volumes (root + data)
- IAM roles (SSM, CloudWatch, S3)
- S3 backup bucket
- CloudWatch monitoring

**Usage**:
```hcl
module "cpanel_server" {
  source = "./modules/cpanel-server"

  customer_domain   = "customer.com"
  vpc_id            = module.network.vpc_id
  subnet_id         = module.network.public_subnet_ids[0]
  security_group_id = module.security.cpanel_security_group_id
  instance_type     = "t3.medium"
  data_volume_size  = 100
}
```

---

## 🔧 Automation Scripts

### provision-customer.sh

Automated customer provisioning script.

**Usage**:
```bash
./automation/provision-customer.sh \
  --domain customer.com \
  --email customer@example.com \
  --instance-type t3.medium \
  --storage 100 \
  --plan premium

# Options:
#   -d, --domain         Customer domain (required)
#   -e, --email          Customer email (required)
#   -i, --instance-type  EC2 type (default: t3.medium)
#   -s, --storage        Data volume GB (default: 100)
#   -p, --plan           Hosting plan (basic|standard|premium)
#   --dry-run            Test without changes
```

**What it does**:
1. Creates customer directory
2. Generates Terraform configuration
3. Initializes remote backend
4. Deploys infrastructure
5. Sends welcome email
6. Stores credentials securely

### send-credentials.py

Email automation for customer credentials.

**Usage**:
```bash
python3 automation/send-credentials.py \
  --domain customer.com \
  --email customer@example.com \
  --outputs customers/customer-com/outputs.json
```

**Features**:
- HTML email template
- Auto-generated secure passwords
- SES integration
- Credential storage

---

## 💰 Hosting Plans

### Basic Plan
```bash
./automation/provision-customer.sh \
  -d customer.com \
  -e email@example.com \
  -i t3.micro \
  -s 50 \
  -p basic

# Cost: ~$25/month
# Suitable for: 5-10 websites
```

### Standard Plan
```bash
./automation/provision-customer.sh \
  -d customer.com \
  -e email@example.com \
  -i t3.medium \
  -s 100 \
  -p standard

# Cost: ~$50/month
# Suitable for: 20-50 websites
```

### Premium Plan
```bash
./automation/provision-customer.sh \
  -d customer.com \
  -e email@example.com \
  -i t3.large \
  -s 200 \
  -p premium

# Cost: ~$85/month
# Suitable for: 50-100 websites
```

---

## 🔒 Security Features

- ✅ **Isolated VPCs**: Each customer in separate network
- ✅ **Encrypted Storage**: EBS volumes encrypted at rest
- ✅ **Secure State**: S3 state bucket with versioning
- ✅ **IAM Roles**: Least privilege access
- ✅ **Security Groups**: Restricted admin access
- ✅ **VPC Flow Logs**: Network monitoring
- ✅ **Backup Encryption**: S3 backups encrypted
- ✅ **State Locking**: DynamoDB prevents conflicts

---

## 📊 Monitoring

Each customer environment includes:
- CloudWatch metrics (CPU, Memory, Disk)
- CloudWatch logs (system logs)
- VPC Flow Logs (network traffic)
- S3 access logs (backup monitoring)

**View metrics**:
```bash
# Customer dashboard
aws cloudwatch get-dashboard \
  --dashboard-name customer-com-production
```

---

## 💾 Backup & Recovery

### Automatic Backups

Each customer gets:
- S3 bucket for backups
- Automated daily backups
- 30-day retention
- Versioning enabled

### Manual Backup

```bash
# Backup customer
cd environments/customers/customer-com
terraform output backup_bucket_name

# Run cPanel backup
aws ssm send-command \
  --instance-ids $(terraform output -raw instance_id) \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["/usr/local/cpanel/bin/backup --force"]'
```

### Disaster Recovery

```bash
# Destroy and recreate
cd environments/customers/customer-com
terraform destroy
terraform apply

# Restore from S3 backup
# Follow cPanel restoration procedures
```

---

## 🔄 Customer Lifecycle

### Onboarding
```bash
# New customer signs up → Payment complete
./automation/provision-customer.sh -d newcustomer.com -e email@example.com

# Customer receives:
# 1. Welcome email
# 2. Login credentials
# 3. DNS instructions
# 4. Getting started guide
```

### Upgrade
```bash
cd environments/customers/customer-com

# Edit Terraform. tfvars
instance_type = "t3.large"
data_volume_size = 200

# Apply changes
terraform apply
```

### Downgrade
```bash
# Note: Storage cannot be reduced, only increased
# Change instance type only
cd environments/customers/customer-com

# Edit Terraform. tfvars
instance_type = "t3.small"

terraform apply
```

### Termination
```bash
cd environments/customers/customer-com

# Backup first!
terraform output backup_bucket_name
# Download backups from S3

# Destroy infrastructure
terraform destroy

# Archive state file
aws s3 cp terraform.tfstate s3://archive-bucket/
```

---

## 🚨 Troubleshooting

### Provisioning Fails

```bash
# Check Terraform state
cd environments/customers/customer-com
terraform show

# Check AWS resources
aws ec2 describe-instances --filters "Name=tag:Customer,Values=customer.com"

# Review logs
terraform apply 2>&1 | tee provision.log
```

### Email Not Sent

```bash
# Verify SES configuration
aws ses get-account-sending-enabled

# Check SES email identity
aws ses list-identities

# Test email
python3 automation/send-credentials.py \
  --domain test.com \
  --email your@email.com \
  --outputs test-outputs.json
```

### State Lock Issues

```bash
# Force unlock (use carefully!)
terraform force-unlock <LOCK_ID>

# Check DynamoDB
aws dynamodb scan --table-name hosting-company-terraform-lock
```

---

## 📈 Scaling

### Add More Customers

```bash
# No limit! Each customer is independent
for domain in customer1.com customer2.com customer3.com; do
  ./automation/provision-customer.sh -d $domain -e admin@$domain
done
```

### Regional Expansion

```bash
# Deploy in multiple regions
./automation/provision-customer.sh \
  -d customer.com \
  -e email@example.com \
  --region eu-west-1

# Or create regional backends
cd backend
terraform workspace new eu-west-1
terraform apply -var region=eu-west-1
```

---

## 💡 Best Practices

1. **Always backup before changes**
   ```bash
   terraform state pull > backup.tfstate
   ```

2. **Use workspaces for environments**
   ```bash
   terraform workspace new production
   terraform workspace new staging
   ```

3. **Tag everything**
   - Customer name
   - Email
   - Hosting plan
   - Provision date

4. **Monitor costs**
   ```bash
   aws ce get-cost-and-usage \
     --time-period Start=2024-01-01,End=2024-01-31 \
     --granularity MONTHLY \
     --metrics BlendedCost \
     --group-by Type=TAG,Key=Customer
   ```

5. **Regular backups testing**
   ```bash
   # Test restore monthly
   ```

---

## 🤝 Support

### Documentation
- [cPanel Docs](https://docs.cpanel.net/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected](https://aws.amazon.com/architecture/well-architected/)

### Common Issues
- State locking: Check DynamoDB table
- Email delivery: Verify SES sandbox mode
- DNS not resolving: Check nameserver configuration
- High costs: Review unused resources

---

## 📝 License

This platform is provided as-is for hosting automation. You are responsible for:
- AWS infrastructure costs
- cPanel/WHM licenses
- Compliance with AWS and cPanel terms
- Nexus Smart Solutions

---

## 🎯 Roadmap

- [ ] Web dashboard for provisioning
- [ ] Billing integration (Stripe/PayPal)
- [ ] Auto-scaling groups for large customers
- [ ] Multi-region high availability
- [ ] Kubernetes for microservices
- [ ] API for third-party integrations

---

**Ready to start?** Begin with [Step 1: Setup Backend Infrastructure](#step-1-setup-backend-infrastructure)

**Questions?** Open an issue or contact support.
