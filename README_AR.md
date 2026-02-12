# 🚀 منصة Neo VPS - نظام استضافة متكامل v2.1

**بنية تحتية احترافية على AWS مع دعم لوحات تحكم متعددة وخوادم DNS مخصصة**

نشر خوادم VPS جاهزة للإنتاج مع لوحة التحكم المفضلة لك في دقائق - آلي بالكامل، آمن، وقابل للتوسع.

---

## ✨ الميزات الرئيسية

### 🎯 **دعم لوحات تحكم متعددة**
- **CyberPanel** (OpenLiteSpeed) - مجاني
- **cPanel/WHM** - احترافي ($15-45/شهر)
- **DirectAdmin** - اقتصادي ($5-29/شهر)
- **خادم نظيف** - بدون لوحة تحكم، تخصيص كامل

### 🌐 **خوادم DNS مخصصة (Bind9)**
- إنشاء Name Server خاص بك
- دعم Domain Registration كامل
- Zone Management تلقائي
- Secondary DNS للموثوقية
- DNSSEC Support

### 🏗️ **عزل كامل لكل عميل**
- **VPC منفصل لكل عميل**
- شبكات معزولة تماماً
- أمان على مستوى البنية التحتية
- لا تداخل بين العملاء
- تحكم كامل في الشبكة

### 🔐 **أمان على مستوى المؤسسات**
- VPC معزول لكل عميل (إلزامي)
- أقراص EBS مشفرة (AES-256)
- نسخ احتياطية S3 مشفرة
- IMDSv2 إلزامي
- IAM roles بأقل الصلاحيات
- حماية SSH بـ Fail2Ban
- تحديثات أمنية تلقائية

---

## 📐 البنية المعمارية

### 🏛️ معمارية العزل الكامل

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
│                                                      │
│  ┌────────────────────────────────────────────┐    │
│  │  Customer C VPC (10.2.0.0/16)              │    │
│  │  ┌──────────────┐                          │    │
│  │  │ CyberPanel   │                          │    │
│  │  │ EC2          │                          │    │
│  │  └──────────────┘                          │    │
│  └────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

### 🔄 تدفق العمل

```
طلب العميل
    ↓
اختيار لوحة التحكم + DNS مخصص؟
    ↓
Terraform Provisioning
    ↓
إنشاء VPC منفصل
    ↓
نشر DNS Server (إذا طُلب)
    ↓
نشر Panel Server
    ↓
تنصيب تلقائي للوحة التحكم
    ↓
تكوين DNS
    ↓
VPS جاهز للاستخدام
```

---

## 🎯 حالات الاستخدام

### 1️⃣ **العميل يريد استضافة + دومين جديد**

```bash
# العميل يشتري domain + hosting
./automation/provision-customer.sh \
  --domain example.com \
  --email customer@example.com \
  --plan premium \
  --panel cpanel \
  --custom-dns true

# النتيجة:
# ✅ VPC منفصل
# ✅ DNS Server (ns1.example.com, ns2.example.com)
# ✅ cPanel Server
# ✅ Domain مسجل ومكون بالكامل
```

**ما يحصل:**
1. إنشاء VPC جديد (10.X.0.0/16)
2. نشر Bind9 DNS Server
3. إنشاء Zone files للدومين
4. نشر cPanel Server
5. ربط الدومين بالـ NS الخاص
6. العميل يستلم:
   - WHM login
   - DNS servers: ns1.example.com, ns2.example.com
   - تحكم كامل في DNS

---

### 2️⃣ **العميل عنده دومين ويريد استضافة فقط**

```bash
./automation/provision-customer.sh \
  --domain existing-domain.com \
  --email customer@example.com \
  --plan standard \
  --panel cyberpanel \
  --custom-dns false  # ← لا يحتاج DNS خاص

# النتيجة:
# ✅ VPC منفصل
# ✅ CyberPanel Server فقط
# ✅ Elastic IP للخادم
```

**ما يحصل:**
1. إنشاء VPC جديد
2. نشر CyberPanel Server
3. العميل يوجه DNS من عند registrar
4. العميل يستلم:
   - CyberPanel login
   - Server IP للـ DNS records

---

### 3️⃣ **Reseller - يريد White Label كامل**

```bash
./automation/provision-customer.sh \
  --domain hosting-business.com \
  --email admin@hosting-business.com \
  --plan enterprise \
  --panel cpanel \
  --custom-dns true \
  --secondary-dns true  # ← DNS ثانوي للموثوقية

# النتيجة:
# ✅ VPC منفصل
# ✅ Primary DNS (ns1.hosting-business.com)
# ✅ Secondary DNS (ns2.hosting-business.com)
# ✅ cPanel/WHM للبيع للعملاء
```

---

## 🔧 المتطلبات

### البرامج المطلوبة
```bash
# Terraform
terraform --version  # >= 1.0

# AWS CLI
aws --version  # >= 2.0

# jq (لمعالجة JSON)
jq --version
```

### AWS Credentials
```bash
# إعداد AWS
aws configure

# أو تصدير المتغيرات
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-east-1"
```

---

## 🚀 البدء السريع

### 1. تحميل المشروع

```bash
git clone https://github.com/your-org/neo-vps.git
cd neo-vps
```

### 2. إعداد Backend للـ State

```bash
cd backend
terraform init
terraform apply

# سيُنشئ:
# - S3 bucket للـ state
# - DynamoDB table للـ locking
```

### 3. نشر عميل جديد

```bash
cd ../automation

# مثال 1: عميل مع DNS خاص
./provision-customer.sh \
  --domain myclient.com \
  --email admin@myclient.com \
  --plan premium \
  --panel cpanel \
  --custom-dns true

# مثال 2: عميل بدون DNS
./provision-customer.sh \
  --domain anotherclient.com \
  --email info@anotherclient.com \
  --plan standard \
  --panel cyberpanel
```

### 4. الوصول للموارد

```bash
# بعد انتهاء التنصيب (60-90 دقيقة):
cd ../environments/customers/myclient.com

# عرض المعلومات
terraform output

# Output:
# whm_url = "https://X.X.X.X:2087"
# cpanel_url = "https://X.X.X.X:2083"
# ns1 = "ns1.myclient.com (X.X.X.X)"
# ns2 = "ns2.myclient.com (X.X.X.X)"
# server_ip = "X.X.X.X"
```

---

## 📦 الخطط المتاحة

### Basic - $50/شهر
```yaml
Instance: t3.micro (1 vCPU, 1GB RAM)
Storage: 50GB SSD
Panel: CyberPanel أو None
DNS: Route53 فقط
Bandwidth: 1TB/شهر
Email: 5 حسابات
Backups: Weekly
```

### Standard - $100/شهر
```yaml
Instance: t3.medium (2 vCPU, 4GB RAM)
Storage: 100GB SSD
Panel: CyberPanel أو cPanel
DNS: Route53 + Custom DNS (اختياري)
Bandwidth: 2TB/شهر
Email: 25 حساب
Backups: Daily
```

### Premium - $165/شهر
```yaml
Instance: t3.large (2 vCPU, 8GB RAM)
Storage: 200GB SSD
Panel: Any (cPanel/DirectAdmin/CyberPanel)
DNS: Route53 + Custom DNS + Secondary
Bandwidth: 5TB/شهر
Email: Unlimited
Backups: Daily + Snapshots
Monitoring: Enhanced
```

### Enterprise - Custom
```yaml
Instance: حسب الطلب
Storage: حسب الطلب
Panel: Multi-panel support
DNS: Full DNS infrastructure
Bandwidth: Unlimited
Email: Unlimited
Backups: Custom schedule
Support: 24/7 Dedicated
SLA: 99.99%
```

---

## 🌐 إعداد DNS الخاص

### كيف يعمل Custom DNS؟

عندما تفعّل `--custom-dns true`:

1. **يُنشأ Bind9 Server**
   - Elastic IP مخصص
   - تكوين آمن (recursion off)
   - Rate limiting
   - DNSSEC ready

2. **Zone Files تلقائية**
   ```bash
   # Zone: example.com
   example.com.     IN SOA  ns1.example.com. admin.example.com. (
                            2026021101 ; Serial
                            3600       ; Refresh
                            1800       ; Retry
                            604800     ; Expire
                            86400 )    ; Minimum TTL
   
   example.com.     IN NS   ns1.example.com.
   example.com.     IN NS   ns2.example.com.
   example.com.     IN A    X.X.X.X
   www              IN A    X.X.X.X
   ns1              IN A    Y.Y.Y.Y
   ns2              IN A    Z.Z.Z.Z
   ```

3. **Nameserver Records**
   - ns1.example.com → DNS Server Primary IP
   - ns2.example.com → DNS Server Secondary IP (إذا مفعّل)

---

## 🔒 الأمان

### 1. Network Isolation
```
✅ VPC منفصل لكل عميل
✅ Security Groups مقفولة
✅ NACLs إضافية (اختياري)
✅ VPC Flow Logs
```

### 2. DNS Security
```
✅ Recursion disabled (لمنع amplification attacks)
✅ Rate limiting (100 queries/sec/IP)
✅ Query logging
✅ DNSSEC support
✅ TSIG for zone transfers
```

### 3. Server Security
```
✅ SSH key-based only
✅ Fail2Ban
✅ Automatic security updates
✅ Encrypted volumes
✅ IMDSv2 enforced
```

### 4. Backup Security
```
✅ S3 encryption at rest
✅ Versioning enabled
✅ Lifecycle policies
✅ Cross-region replication (اختياري)
```

---

## 📊 المراقبة

### CloudWatch Alarms (تلقائي)
- ✅ CPU Utilization > 80%
- ✅ Status Check Failed
- ✅ Disk Usage > 85%
- ✅ Memory Usage > 90%
- ✅ DNS Query Rate anomalies

### Logs
```bash
# Server logs
/var/log/neo-vps-setup.log

# DNS logs
/var/log/named/queries.log
/var/log/named/security.log

# CloudWatch Logs
aws logs tail /aws/ec2/customer-domain
```

---

## 🔄 النسخ الاحتياطي

### تلقائي
- **Daily EBS Snapshots** (الساعة 3 صباحاً UTC)
- **S3 Backups** (يومياً)
- **Retention:** 30 يوم (قابل للتخصيص)

### يدوي
```bash
# إنشاء snapshot فوري
aws ec2 create-snapshot \
  --volume-id vol-xxxxx \
  --description "Manual backup"

# استعادة من snapshot
./scripts/restore-from-snapshot.sh snap-xxxxx
```

---

## 🛠️ الصيانة

### تحديث لوحة التحكم

```bash
# cPanel
ssh root@server-ip
/scripts/upcp

# CyberPanel
cyberpanel upgrade

# DirectAdmin
cd /usr/local/directadmin
./update.sh
```

### تحديث DNS Server

```bash
ssh root@dns-server-ip
yum update bind -y
systemctl restart named
```

### إضافة Zone جديد

```bash
# SSH to DNS server
nano /var/named/newdomain.com.zone

# Add zone
cat >> /etc/named.conf << EOF
zone "newdomain.com" {
    type master;
    file "/var/named/newdomain.com.zone";
};
EOF

# Reload
rndc reload
```

---

## 🐛 استكشاف الأخطاء

### DNS لا يعمل

```bash
# فحص Bind9
systemctl status named
named-checkconf
named-checkzone example.com /var/named/example.com.zone

# فحص الاتصال
dig @dns-server-ip example.com
nslookup example.com dns-server-ip
```

### لوحة التحكم لا تعمل

```bash
# فحص الخدمة
systemctl status cpanel  # cPanel
systemctl status lscpd    # CyberPanel

# فحص اللوجات
tail -f /var/log/neo-vps-setup.log
```

### مشكلة في الشبكة

```bash
# فحص Security Group
aws ec2 describe-security-groups --group-ids sg-xxxxx

# فحص Route Table
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-xxxxx"

# فحص Internet Gateway
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=vpc-xxxxx"
```

---

## 📞 الدعم

### الوثائق
- 📖 [Architecture Guide](docs/ARCHITECTURE.md)
- 🔧 [Troubleshooting](docs/TROUBLESHOOTING.md)
- 🔐 [Security Best Practices](docs/SECURITY.md)
- 🌐 [DNS Management](docs/DNS.md)

### المجتمع
- 💬 Discord: [رابط هنا]
- 📧 Email: support@neo-vps.com
- 🐛 Issues: [GitHub Issues](https://github.com/your-org/neo-vps/issues)

---

## 📄 الترخيص

MIT License - انظر [LICENSE](LICENSE) للتفاصيل

---

## 🙏 شكر خاص

- AWS لتوفير البنية التحتية
- Terraform لأداة IaC الرائعة
- مجتمع cPanel/CyberPanel/DirectAdmin
- ISC لـ Bind9 DNS Server

---

**صُنع بـ ❤️ للمستضيفين العرب**

**النسخة:** 2.1.0  
**آخر تحديث:** فبراير 2026
