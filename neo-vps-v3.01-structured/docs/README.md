# 🚀 Neo VPS - DNS Automation Ready

**Production-Ready DNS Automation for AlmaLinux + Bind9**

This package contains everything needed to automate DNS management for the Neo VPS platform.

---

## ✅ What's Included

### 1. **Bind9 Quick Setup Script**
```bash
scripts/bind9-quick-setup.sh
```
- ⚡ Runs in <30 seconds on AMI with Bind9 pre-installed
- 🔧 Configures zones automatically
- 🔒 Security hardened (recursion off, rate limiting)
- 📝 Creates zone files with all DNS records
- ✅ Validates configuration before applying
- 💾 Backs up to S3
- 📊 Updates DynamoDB state

### 2. **Python DNS Automation Tool**
```bash
scripts/dns-automation.py
```
- 🌐 Creates Route53 hosted zones
- 📝 Creates comprehensive DNS records
- 🧪 Tests nameservers
- ✅ Verifies DNS propagation
- 💾 Saves to DynamoDB
- 📧 Sends SNS notifications
- 📄 Generates detailed reports

### 3. **Terraform Integration**
```hcl
terraform/dns-module.tf
```
- Integration with existing Terraform modules
- Automatic AMI selection
- User-data templating
- Variables for all configurations

---

## 🎯 Quick Start

### Prerequisites
✅ AlmaLinux AMI with Bind9 installed
✅ AWS credentials configured
✅ DynamoDB table: `neo-dns-servers`
✅ SNS topic for notifications

### Step 1: Deploy DNS Server
```bash
terraform apply \
  -var="domain=example.com" \
  -var="enable_custom_dns=true"
```

### Step 2: Auto-Configuration
The `bind9-quick-setup.sh` runs automatically via user-data and:
- Configures Bind9
- Creates zone files
- Sets up security
- Tests DNS resolution

### Step 3: Run DNS Automation
```bash
python3 scripts/dns-automation.py \
  example.com \
  54.23.45.67 \
  52.10.20.30 \
  52.10.20.31
```

This creates Route53 zone and all DNS records.

---

## 📦 DNS Records Created

| Type | Name | Value | Purpose |
|------|------|-------|---------|
| A | @ | server_ip | Main domain |
| A | www | server_ip | WWW subdomain |
| A | mail | server_ip | Mail server |
| A | ns1 | ns1_ip | Primary nameserver |
| A | ns2 | ns2_ip | Secondary nameserver |
| MX | @ | mail.domain | Mail routing |
| TXT | @ | SPF record | Email authentication |
| TXT | _dmarc | DMARC policy | Email policy |
| CNAME | ftp | @ | FTP subdomain |
| CNAME | webmail | @ | Webmail subdomain |
| CNAME | cpanel | @ | cPanel subdomain |

---

## 🔧 Configuration Files

### Bind9 Configuration
```
/etc/named.conf           - Main config
/etc/named/zones.conf     - Zones config
/var/named/zones/         - Zone files
/var/log/named/           - Logs
```

### Zone File Example
```dns
$TTL 86400
@   IN  SOA ns1.example.com. admin.example.com. (
        2026021201  ; Serial
        3600        ; Refresh
        1800        ; Retry
        604800      ; Expire
        86400 )     ; Minimum TTL

@       IN  NS      ns1.example.com.
@       IN  NS      ns2.example.com.

ns1     IN  A       52.10.20.30
ns2     IN  A       52.10.20.31

@       IN  A       54.23.45.67
www     IN  A       54.23.45.67
mail    IN  A       54.23.45.67

@       IN  MX  10  mail.example.com.
```

---

## 🧪 Testing

### Test Local DNS Resolution
```bash
dig @localhost example.com
dig @localhost www.example.com
dig @localhost NS example.com
```

### Test from Public DNS
```bash
dig example.com @8.8.8.8
dig NS example.com
```

### Test Custom Nameservers
```bash
dig @ns1.example.com example.com
dig @52.10.20.30 example.com
```

---

## 📊 Monitoring & Logs

### Check Bind9 Status
```bash
systemctl status named
journalctl -u named -f
```

### View Query Logs
```bash
tail -f /var/log/named/queries.log
tail -f /var/log/named/security.log
```

### Check Setup Log
```bash
tail -f /var/log/neo-dns-quick-setup.log
```

---

## 🔒 Security Features

✅ **Recursion disabled** - Prevents amplification attacks
✅ **Rate limiting** - 100 queries/sec per IP
✅ **Query logging** - All queries logged
✅ **Firewall configured** - Only DNS ports open
✅ **DNSSEC ready** - DNSSEC validation enabled

---

## 🛠️ Management Commands

### Add DNS Record
```bash
/usr/local/bin/neo-dns-add-record example.com test A 1.2.3.4
```

### Reload Zone
```bash
rndc reload example.com
```

### Validate Configuration
```bash
named-checkconf
named-checkzone example.com /var/named/zones/example.com.zone
```

---

## 📞 Troubleshooting

### DNS Not Resolving
```bash
# Check Bind9 status
systemctl status named

# Validate config
named-checkconf

# Check zone file
named-checkzone example.com /var/named/zones/example.com.zone

# Test locally
dig @localhost example.com
```

### Propagation Issues
DNS propagation can take 24-48 hours. Check status:
```bash
dig NS example.com @8.8.8.8
whois example.com | grep "Name Server"
```

---

## 📄 File Structure

```
neo-vps-dns-ready/
├── scripts/
│   ├── bind9-quick-setup.sh      # Main setup script
│   ├── dns-automation.py          # Python automation
│   └── tests/
│       └── test-dns.sh            # Testing script
├── terraform/
│   ├── dns-module.tf              # DNS module
│   └── variables.tf               # Variables
├── docs/
│   ├── DNS_SETUP_GUIDE.md         # Detailed guide
│   └── TROUBLESHOOTING.md         # Common issues
└── README.md                      # This file
```

---

## ✅ Completion Checklist

After running the automation:

- [ ] DNS server is running
- [ ] Zone file created
- [ ] Configuration validated
- [ ] Firewall configured
- [ ] Route53 zone created
- [ ] DNS records created
- [ ] Nameservers tested
- [ ] Backup saved to S3
- [ ] DynamoDB updated
- [ ] Notification sent

---

## 🎉 Success Indicators

When everything is working:
```
✅ Bind9 service active
✅ dig @localhost example.com returns server IP
✅ Route53 zone created
✅ Nameservers responding
✅ /root/DNS_INFO.txt created
✅ /var/neo-dns-setup-complete exists
```

---

## 📧 Support

- 📖 Documentation: `/docs/`
- 🐛 Issues: GitHub Issues
- 📧 Email: support@neo-vps.com

---

**Version:** 1.0.0
**Last Updated:** February 2026
**Status:** Production Ready ✅
