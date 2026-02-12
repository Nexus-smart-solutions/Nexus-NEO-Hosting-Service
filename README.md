# 🚀 Neo VPS - Multi-Panel Hosting Platform v2.0

**Enterprise-Grade AWS Infrastructure as Code with Multi-Control Panel Support**

Deploy production-ready VPS instances with your choice of control panel in minutes - fully automated, secure, and scalable.

---

## ✨ What's New in v2.0

### 🎯 **Multi-Panel Support**
- **CyberPanel** (OpenLiteSpeed) - FREE
- **cPanel/WHM** - Premium ($15-45/month)
- **DirectAdmin** - Budget-friendly ($5-29/month)
- **Clean Server** - No panel, full customization

### 🏗️ **Golden AMI Architecture**
- Single clean base AMI for all deployments
- Control panel installed via User Data on first boot
- Easy to maintain and update
- Significant cost and time savings

### 📦 **Dynamic Provisioning**
- Customer chooses panel at order time
- Automatic installation during boot
- No pre-baked AMIs needed
- Faster deployment pipeline

---

## 🎨 Architecture Overview

```
Customer Order
    ↓
[ Panel Selection: CyberPanel | cPanel | DirectAdmin | None ]
    ↓
Terraform Provisioning
    ↓
EC2 Instance Launch (Clean Golden AMI)
    ↓
User Data Script Execution
    ↓
Selected Panel Installation
    ↓
Ready to Use VPS
```

### Key Benefits:
✅ **One AMI** instead of multiple panel-specific AMIs  
✅ **Faster updates** - update scripts, not AMIs  
✅ **Customer choice** - flexibility at order time  
✅ **Lower costs** - no storage for multiple AMIs  
✅ **Easier maintenance** - centralized configuration  

---

## 📋 Features

### 🔒 **Enterprise Security**
- Isolated VPC per customer (optional)
- Encrypted EBS volumes (AES-256)
- S3 encrypted backups with versioning
- IMDSv2 enforced
- IAM roles with least privilege
- Fail2Ban SSH protection
- Automatic security updates

### 🤖 **Complete Automation**
- One-command customer provisioning
- Automatic panel installation
- DNS configuration support
- Post-deployment instructions
- Terraform workspace management

### 💰 **Cost Optimized**
- Pay only for active resources
- Right-sized by use case
- Optional NAT Gateway
- S3 lifecycle policies
- Detailed cost estimates

### 📊 **Monitoring & Backup**
- CloudWatch metrics and alarms
- Daily EBS snapshots
- S3 backup integration
- Performance monitoring
- Status checks

---

## 💵 Control Panel Comparison

| Panel | Cost | Install Time | Best For | Features |
|-------|------|--------------|----------|----------|
| **CyberPanel** | FREE | 15-20 min | Most users | OpenLiteSpeed, PowerDNS, Postfix, FTP |
| **cPanel** | $15-45/mo | 60-90 min | Enterprise | Industry standard, extensive features |
| **DirectAdmin** | $5-29/mo | Manual | Budget-conscious | Simple, lightweight |
| **None** | FREE | 2-3 min | Developers | Full customization, clean slate |

---

## 🚀 Quick Start

### 1. Prerequisites

- **Terraform** >= 1.0
- **AWS CLI** configured
- **AWS Account** with appropriate permissions
- **SSH Key Pair** created in AWS
- **Golden AMI** (clean AlmaLinux or Ubuntu)

### 2. Setup Backend (One-Time)

```bash
cd backend
terraform init
terraform apply

# Note the outputs for later use
```

### 3. Create Golden AMI (One-Time)

**Option A: Use Public AMI**
```bash
# AlmaLinux 8 (Recommended)
# AMI ID will be fetched automatically

# Or specify custom AMI
use_custom_ami = true
custom_ami_id = "ami-xxxxx"
```

**Option B: Create Your Own**
```bash
# Launch fresh AlmaLinux instance
# Update system only
# Create AMI
# Use AMI ID in configuration
```

### 4. Provision Customer VPS

```bash
# Using automation script
./automation/provision-customer.sh \
  --domain example.com \
  --email customer@example.com \
  --panel cyberpanel \
  --plan standard

# Or manually
cd environments/customers
cp ../../terraform.tfvars.example customer-com/terraform.tfvars
# Edit terraform.tfvars
cd customer-com
terraform init
terraform apply
```

### 5. Access Your VPS

```bash
cd environments/customers/customer-com
terraform output

# Follow the "next_steps" output for panel-specific instructions
```

---

## 📁 Project Structure

```
neo-vps/
├── modules/
│   ├── panel-server/          # Multi-panel server module
│   │   ├── main.tf            # EC2, IAM, S3, monitoring
│   │   ├── variables.tf       # Configuration variables
│   │   ├── outputs.tf         # Access info, URLs, instructions
│   │   └── user-data/         # Installation scripts
│   │       ├── cyberpanel.sh.tpl
│   │       ├── cpanel.sh.tpl
│   │       ├── directadmin.sh.tpl
│   │       └── none.sh.tpl
│   ├── network/               # VPC, Subnets, NAT, IGW
│   └── security/              # Security Groups
│
├── backend/                   # Terraform state management
│   ├── main.tf               # S3 + DynamoDB
│   ├── variables.tf
│   └── outputs.tf
│
├── automation/               # Provisioning scripts
│   └── provision-customer.sh
│
├── environments/             # Customer deployments
│   └── customers/
│       └── [customer-domain]/
│
├── docs/                     # Documentation
│   ├── INSTALLATION.md
│   ├── PANELS.md
│   └── TROUBLESHOOTING.md
│
├── README.md                 # This file
├── CHANGELOG.md              # Version history
├── .gitignore
└── terraform.tfvars.example
```

---

## 🎯 Usage Examples

### Example 1: CyberPanel VPS (Most Popular)

```bash
./automation/provision-customer.sh \
  --domain mysite.com \
  --email admin@mysite.com \
  --panel cyberpanel \
  --instance-type t3.medium \
  --storage 100
```

**Result:**
- CyberPanel with OpenLiteSpeed
- 15-20 minute installation
- FREE control panel
- Perfect for most websites

**Access:** https://YOUR_IP:8090

---

### Example 2: cPanel Enterprise Setup

```bash
./automation/provision-customer.sh \
  --domain enterprise.com \
  --email admin@enterprise.com \
  --panel cpanel \
  --instance-type t3.large \
  --storage 200 \
  --admin-ip "203.0.113.0/24"
```

**Result:**
- cPanel/WHM installation
- 60-90 minute installation
- Requires cPanel license
- IP-restricted admin access

**Access:** https://YOUR_IP:2087

---

### Example 3: Custom Developer Server

```bash
./automation/provision-customer.sh \
  --domain dev.example.com \
  --email dev@example.com \
  --panel none \
  --instance-type t3.small \
  --storage 50
```

**Result:**
- Clean server with essentials
- 2-3 minute setup
- Full customization freedom
- Firewall + Fail2Ban configured

---

### Example 4: DirectAdmin Budget Setup

```bash
./automation/provision-customer.sh \
  --domain budget.com \
  --email admin@budget.com \
  --panel directadmin \
  --instance-type t3.micro \
  --storage 50
```

**Result:**
- DirectAdmin preparation
- Manual license input required
- Budget-friendly option
- Simple interface

**Access:** https://YOUR_IP:2222

---

## 🔐 Security Best Practices

### 1. Restrict Admin Access

```bash
# cPanel/WHM - Office IP only
--admin-ip "203.0.113.0/24"

# SSH - Specific IP
--ssh-ip "203.0.113.10/32"
```

### 2. Use SSM Session Manager

```bash
# No SSH key needed
aws ssm start-session --target i-xxxxx

# More secure than SSH
# Logged and auditable
```

### 3. Enable CloudWatch Alarms

```hcl
enable_cloudwatch_alarms = true
enable_detailed_monitoring = true
```

### 4. Regular Backups

```hcl
enable_daily_snapshots = true
snapshot_retention_days = 7
backup_retention_days = 30
```

---

## 💰 Cost Analysis

### Basic Plan
```
Instance (t3.micro):    $7.30/month
Root Volume (30GB):     $2.40/month
Data Volume (50GB):     $4.00/month
S3 Backups:             $0.50/month
────────────────────────────────
Total Cost:            $14.20/month
Suggested Price:       $49/month
Profit Margin:         245%
```

### Standard Plan (Most Popular)
```
Instance (t3.medium):   $30.37/month
Root Volume (50GB):     $4.00/month
Data Volume (100GB):    $8.00/month
NAT Gateway:            $32.00/month
S3 Backups:             $1.15/month
────────────────────────────────
Total Cost:            $80.02/month
Suggested Price:      $149/month
Profit Margin:         86%
```

### Premium Plan
```
Instance (t3.large):    $60.74/month
Root Volume (50GB):     $4.00/month
Data Volume (200GB):   $16.00/month
NAT Gateway:           $32.00/month
S3 Backups:             $4.60/month
CloudWatch:             $3.00/month
────────────────────────────────
Total Cost:           $142.84/month
Suggested Price:      $299/month
Profit Margin:        109%
```

### Cost Optimization Tips

**Development Environment:**
```hcl
enable_nat_gateway = false  # Save $32/month
instance_type = "t3.micro"  # Save $23/month
```

**Production with Budget:**
```hcl
instance_type = "t3.small"  # Balance performance/cost
enable_detailed_monitoring = false
```

---

## 🛠️ Panel-Specific Guides

### CyberPanel

**Installation Time:** 15-20 minutes

**Access:**
- URL: https://YOUR_IP:8090
- Username: admin
- Password: `cat /root/.cyberpanel_password`

**Features:**
- OpenLiteSpeed web server
- PowerDNS
- Postfix mail server
- Pure-FTPd
- Free SSL (Let's Encrypt)
- File Manager
- Email accounts
- Databases (MySQL/MariaDB)

**Post-Install:**
1. Login to panel
2. Create first website
3. Point domain DNS to server IP
4. Install SSL certificate
5. Configure email accounts

---

### cPanel/WHM

**Installation Time:** 60-90 minutes

**Access:**
- WHM: https://YOUR_IP:2087
- cPanel: https://YOUR_IP:2083
- Username: root
- Password: `cat /root/.whm_password`

**License Required:**
Get from: https://cpanel.net/pricing/

**Features:**
- Industry-standard interface
- Apache/LiteSpeed
- Comprehensive email system
- DNS management
- Security features
- Extensive plugin ecosystem

**Post-Install:**
1. Complete initial setup wizard
2. Add cPanel license
3. Create first account
4. Configure backups to S3
5. Setup DNS zones

---

### DirectAdmin

**Installation Time:** Manual (15-30 minutes)

**Setup Required:**
1. Get license: https://www.directadmin.com/trial.php
2. SSH to server
3. Read guide: `cat /root/DIRECTADMIN_INSTALL_GUIDE.txt`
4. Run installer with license

**Access:**
- URL: https://YOUR_IP:2222
- Username: admin
- Password: Set during installation

**Features:**
- Simple, clean interface
- Apache web server
- Email management
- DNS management
- File manager
- Budget-friendly

---

### Clean Server (No Panel)

**Setup Time:** 2-3 minutes

**Included:**
- ✅ Firewall (firewalld)
- ✅ Fail2Ban (SSH protection)
- ✅ Auto security updates
- ✅ Essential tools (vim, htop, curl, wget, git)
- ✅ 2GB swap file
- ✅ System optimizations

**Perfect For:**
- Custom applications
- Developers
- Specific requirements
- Learning purposes

**Next Steps:**
```bash
# Install web server
dnf install nginx  # or apache

# Install database
dnf install mariadb-server

# Install runtime
dnf install php php-fpm  # or python, nodejs

# Deploy application
```

---

## 🔄 Updating Infrastructure

### Change Instance Type

```bash
cd environments/customers/customer-com

# Edit terraform.tfvars
instance_type = "t3.large"

# Apply changes (causes restart)
terraform plan
terraform apply
```

### Add Storage

```bash
# Edit terraform.tfvars
data_volume_size = 200

# Apply (no downtime)
terraform apply
```

### Switch Control Panel

⚠️ **Not recommended** - requires full rebuild

```bash
# Backup data first!
# Then destroy and recreate with new panel
terraform destroy
# Change control_panel in terraform.tfvars
terraform apply
```

---

## 🚨 Troubleshooting

### Installation Not Complete?

```bash
# SSH to server
ssh root@YOUR_IP

# Check installation log
tail -f /var/log/neo-vps-setup.log

# Check if complete
cat /var/log/installation_complete.flag
```

### Can't Access Control Panel?

1. Check installation is complete
2. Verify security group rules
3. Try HTTP instead of HTTPS initially
4. Check server firewall

```bash
# On server
firewall-cmd --list-all
systemctl status lscpd  # CyberPanel
systemctl status cpanel  # cPanel
```

### Backend State Lock?

```bash
terraform force-unlock <lock-id>
```

### Need to Rebuild Customer?

```bash
cd environments/customers/customer-com
terraform destroy
cd ../../..
rm -rf environments/customers/customer-com
# Re-provision
```

---

## 📚 Additional Documentation

- [Installation Guide](docs/INSTALLATION.md)
- [Panel Comparison](docs/PANELS.md)
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- [Security Best Practices](docs/SECURITY.md)
- [Cost Optimization](docs/COST_OPTIMIZATION.md)

---

## 🎓 Best Practices

### Golden AMI Management
1. Keep AMI clean and minimal
2. Only update system packages
3. Don't install panels in AMI
4. Create new AMI quarterly
5. Test thoroughly before production

### Customer Provisioning
1. Use automation script when possible
2. Store customer configs in version control
3. Document custom configurations
4. Regular backups before changes
5. Monitor costs per customer

### Security
1. Enable CloudWatch alarms
2. Regular security updates
3. Use SSM instead of SSH when possible
4. Restrict admin panel access by IP
5. Enable MFA on panels
6. Regular backup testing

### Cost Management
1. Right-size instances based on usage
2. Disable NAT for dev environments
3. Use Reserved Instances for stable workloads
4. Monitor and delete unused snapshots
5. Set up billing alerts

---

## 🔗 Useful Links

- [AWS VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [CyberPanel Documentation](https://cyberpanel.net/docs/)
- [cPanel Documentation](https://docs.cpanel.net/)
- [DirectAdmin Docs](https://docs.directadmin.com/)

---

## 📄 License

MIT License - See LICENSE file

---

## 🙏 Credits

- **Terraform** by HashiCorp
- **CyberPanel** by CyberPanel Team
- **cPanel/WHM** by cPanel, LLC
- **DirectAdmin** by DirectAdmin
- **AWS** by Amazon Web Services
- **AlmaLinux** by AlmaLinux OS Foundation

---

## 📞 Support

For issues or questions:
1. Check documentation in `/docs`
2. Review troubleshooting guide
3. Check server logs
4. Contact panel-specific support

---

**Made with ❤️ for the hosting community**

**Neo VPS v2.0** - The Modern Multi-Panel Hosting Platform
