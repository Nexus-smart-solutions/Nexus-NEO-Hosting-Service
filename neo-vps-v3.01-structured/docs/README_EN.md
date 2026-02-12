# 🚀 Neo VPS Platform - Enterprise Hosting Solution v2.1

**Production-grade AWS Infrastructure with Multi-Panel Support & Custom DNS Servers**

Deploy production-ready VPS instances with your preferred control panel in minutes - fully automated, secure, and infinitely scalable.

---

## ✨ Key Features

### 🎯 **Multi-Panel Support**
- **CyberPanel** (OpenLiteSpeed) - FREE
- **cPanel/WHM** - Enterprise ($15-45/month)
- **DirectAdmin** - Budget-friendly ($5-29/month)
- **Clean Server** - No panel, full customization

### 🌐 **Custom DNS Servers (Bind9)**
- Create your own Name Servers
- Full domain registration support
- Automatic zone management
- Secondary DNS for reliability
- DNSSEC ready

### 🏗️ **Complete Customer Isolation**
- **Dedicated VPC per customer**
- Fully isolated networks
- Infrastructure-level security
- Zero cross-customer interference
- Full network control

### 🔐 **Enterprise Security**
- Isolated VPC per customer (mandatory)
- Encrypted EBS volumes (AES-256)
- Encrypted S3 backups with versioning
- IMDSv2 enforced
- IAM roles with least privilege
- Fail2Ban SSH protection
- Automatic security updates

---

## 📐 Architecture

### 🏛️ Full Isolation Architecture

```
┌─────────────────────────────────────────────────────┐
│                    AWS ACCOUNT                       │
│                                                      │
│  ┌────────────────────────────────────────────┐    │
│  │  Customer A VPC (10.0.0.0/16)              │    │
│  │  ┌──────────────┐  ┌──────────────┐       │    │
│  │  │ DNS Server   │  │ cPanel Server│       │    │
│  │  │ Bind9        │  │ EC2          │       │    │
│  │  │ ns1/ns2      │  │              │       │    │
│  │  └──────────────┘  └──────────────┘       │    │
│  │          │                  │              │    │
│  │  ┌──────────────────────────────┐         │    │
│  │  │   S3 Backups (Customer A)    │         │    │
│  │  └──────────────────────────────┘         │    │
│  └────────────────────────────────────────────┘    │
│                                                      │
│  ┌────────────────────────────────────────────┐    │
│  │  Customer B VPC (10.1.0.0/16)              │    │
│  │  ┌──────────────┐  ┌──────────────┐       │    │
│  │  │ DNS Server   │  │ DirectAdmin  │       │    │
│  │  │ Bind9        │  │ EC2          │       │    │
│  │  └──────────────┘  └──────────────┘       │    │
│  └────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### Prerequisites
```bash
# Terraform
terraform --version  # >= 1.0

# AWS CLI
aws --version  # >= 2.0

# Configure AWS
aws configure
```

### Deploy New Customer

```bash
# Example 1: Customer with custom DNS
./automation/provision-customer.sh \
  --domain myclient.com \
  --email admin@myclient.com \
  --plan premium \
  --panel cpanel \
  --custom-dns true

# Example 2: Customer without custom DNS
./automation/provision-customer.sh \
  --domain client.com \
  --email info@client.com \
  --plan standard \
  --panel cyberpanel
```

---

## 📦 Plans

| Plan | Price | Instance | Storage | Panel | DNS |
|------|-------|----------|---------|-------|-----|
| **Basic** | $50/mo | t3.micro | 50GB | CyberPanel | Route53 |
| **Standard** | $100/mo | t3.medium | 100GB | Any | Route53 + Custom |
| **Premium** | $165/mo | t3.large | 200GB | Any | Full DNS |
| **Enterprise** | Custom | Custom | Custom | Multi-panel | Full Infrastructure |

---

## 🔒 Security Features

### Network Isolation
✅ Dedicated VPC per customer  
✅ Locked-down Security Groups  
✅ VPC Flow Logs  
✅ Optional NACLs  

### DNS Security
✅ Recursion disabled  
✅ Rate limiting (100 q/s/IP)  
✅ Query logging  
✅ DNSSEC support  
✅ TSIG for zone transfers  

### Server Security
✅ SSH key-based only  
✅ Fail2Ban protection  
✅ Automatic updates  
✅ Encrypted volumes  
✅ IMDSv2 enforced  

---

## 📊 Monitoring

### CloudWatch Alarms (Automatic)
- CPU Utilization > 80%
- Status Check Failed
- Disk Usage > 85%
- Memory Usage > 90%
- DNS Query anomalies

---

## 🔄 Backups

### Automatic
- Daily EBS Snapshots (3 AM UTC)
- Daily S3 Backups
- 30-day retention (customizable)

### Manual
```bash
# Create snapshot
aws ec2 create-snapshot --volume-id vol-xxxxx

# Restore
./scripts/restore-from-snapshot.sh snap-xxxxx
```

---

## 🛠️ Use Cases

### 1. Customer wants Hosting + New Domain

```bash
./automation/provision-customer.sh \
  --domain example.com \
  --email customer@example.com \
  --plan premium \
  --panel cpanel \
  --custom-dns true

# Result:
# ✅ Dedicated VPC
# ✅ DNS Server (ns1.example.com, ns2.example.com)
# ✅ cPanel Server
# ✅ Fully configured domain
```

### 2. Customer has Domain, wants Hosting only

```bash
./automation/provision-customer.sh \
  --domain existing-domain.com \
  --email customer@example.com \
  --plan standard \
  --panel cyberpanel
  
# Result:
# ✅ Dedicated VPC
# ✅ CyberPanel Server only
# ✅ Elastic IP for server
```

### 3. Reseller - White Label Solution

```bash
./automation/provision-customer.sh \
  --domain hosting-company.com \
  --email admin@hosting-company.com \
  --plan enterprise \
  --panel cpanel \
  --custom-dns true \
  --secondary-dns true

# Result:
# ✅ Dedicated VPC
# ✅ Primary DNS (ns1.hosting-company.com)
# ✅ Secondary DNS (ns2.hosting-company.com)
# ✅ cPanel/WHM for reselling
```

---

## 🐛 Troubleshooting

### DNS Issues
```bash
systemctl status named
named-checkconf
dig @dns-server-ip example.com
```

### Panel Issues
```bash
systemctl status cpanel
tail -f /var/log/neo-vps-setup.log
```

### Network Issues
```bash
aws ec2 describe-security-groups --group-ids sg-xxxxx
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-xxxxx"
```

---

## 📞 Support

- 📖 Documentation: [docs/](docs/)
- 💬 Discord: [Link here]
- 📧 Email: support@neo-vps.com
- 🐛 Issues: [GitHub Issues](https://github.com/your-org/neo-vps/issues)

---

## 📄 License

MIT License - See [LICENSE](LICENSE)

---

**Made with ❤️ for hosters worldwide**

**Version:** 2.1.0  
**Last Updated:** February 2026
