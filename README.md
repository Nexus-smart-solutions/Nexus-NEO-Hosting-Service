
# 🚀 Nexus Neo – Version 3 - Provided By: Nexus Solutions Team

## Multi-OS Automated Hosting Provisioning Engine ##

---

# 📌 Overview

Neo is a Terraform-driven infrastructure engine designed to provision hosting environments on AWS with full OS flexibility and automated deployment logic.

The system allows dynamic provisioning based on:

* Selected Operating System
* Selected Control Panel
* Resource configuration
* Region

It is built around Golden AMIs and Infrastructure as Code principles to ensure reproducibility and stability.

---

# 🏗 High-Level Architecture

```
Client Order
     ↓
(Backend Control Layer – upcoming)
     ↓
Terraform Provision Engine
     ↓
AWS Infrastructure
     ↓
Golden AMI Launch
     ↓
Userdata Execution
     ↓
DNS Configuration
     ↓
Health Validation
```

---

# 🧱 Infrastructure Components

## 1️⃣ Network Layer

* VPC
* Public Subnets
* Internet Gateway
* Route Tables

## 2️⃣ Security Layer

* Security Groups
* IAM Roles
* Instance Profiles

## 3️⃣ Compute Layer

* EC2 Instances
* Elastic IP Allocation
* Golden AMI-based provisioning

## 4️⃣ DNS Layer

* Dedicated Bind9 Server (AlmaLinux)
* Authoritative DNS
* Automated Zone Management

## 5️⃣ Automation

* Terraform Modules
* Userdata Templates
* GitHub Actions CI

---

# 🖥 Supported Operating Systems

| OS                   | Purpose                    |
| -------------------- | -------------------------- |
| AlmaLinux            | Primary Hosting OS         |
| Ubuntu 22.04 LTS     | Alternative Hosting OS     |
| AlmaLinux (DNS Node) | Dedicated Bind9 DNS Server |

The client selects the OS during provisioning.

---

# 📀 Golden AMIs

## AlmaLinux Golden AMI

* Hardened SSH configuration
* Base system updated
* Required base packages installed
* No control panel pre-installed
* Cleaned via cloud-init before snapshot
* Used for hosting nodes and DNS nodes

**AMI ID:**

```
ami-ALMA-GOLDEN-ID
```

---

## Ubuntu 22.04 Golden AMI

* Official Ubuntu 22.04 LTS (Jammy)
* cloud-init enabled
* snap disabled
* Hardened SSH
* Clean hosting base image
* No panel pre-installed

**AMI ID:**

```
ami-UBUNTU-GOLDEN-ID
```

---

# 🌐 Name Servers (Authoritative DNS)

DNS is isolated from hosting nodes.

Primary DNS Server (AlmaLinux Bind9):

```
ns1.yourdomain.com
ns2.yourdomain.com
```

Example:

```
ns1.yourdomain.com → x.x.x.x
ns2.yourdomain.com → x.x.x.x
```

* Dedicated DNS EC2 instance
* Bind9 configured manually
* Zone records provisioned via automation
* Hosting nodes do NOT run DNS

---

# 📁 Project Structure – Version 3

```
infra/
 ├── main.tf
 ├── variables.tf
 ├── outputs.tf
 ├── modules/
 │     ├── network/
 │     ├── security/
 │     ├── panel-server/
 │     └── dns-server/
 ├── userdata/
 │     ├── cpanel.sh.tpl
 │     ├── cyberpanel.sh.tpl
 │     ├── directadmin.sh.tpl
 │     └── none.sh.tpl
 └── scripts/

.github/
 └── workflows/
       terraform.yml

README.md
```

---

# ⚙ Provision Flow (Detailed)

1. Terraform initializes the provider
2. Network module deploys VPC and routing
3. Security module creates required groups
4. EC2 instance launches from selected Golden AMI
5. Elastic IP attaches
6. Userdata executes selected panel installation
7. DNS zone is created on the Bind9 server
8. Health checks validate:

   * SSH connectivity
   * HTTP response
   * Panel port availability
   * DNS resolution
9. Snapshot (optional post-provision)
10. Instance marked as running

---

# 🧩 Supported Panels

| Panel       | Port     |
| ----------- | -------- |
| cPanel      | 2087     |
| CyberPanel  | 8090     |
| DirectAdmin | 2222     |
| None        | Clean OS |

Panels are installed dynamically using userdata templates.

---

# 🔄 CI/CD Pipeline

GitHub Actions workflow includes:

* terraform fmt check
* terraform init (backend disabled in CI)
* terraform validate
* terraform plan

Apply is intentionally disabled in CI until the control layer is implemented.

Workflow file location:

```
.github/workflows/terraform.yml
```

---

# 🔐 Security Considerations

* No tfstate committed
* No hardcoded AWS credentials
* Use IAM Roles or GitHub Secrets
* SSH password authentication disabled
* Golden AMIs versioned
* DNS isolated from the hosting layer

---

# 🧠 Current System Status (Version 3)

✅ Multi-OS support
✅ Golden AMIs ready
✅ DNS isolated and stable
✅ Terraform modularized
✅ Userdata panel automation
✅ CI validation pipeline

Planned next:

* Backend Control Layer
* Order State Management
* Retry & Rollback Logic
* Remote Terraform State (S3 + DynamoDB lock)

---

# 🧪 Local Testing

Initialize:

```
terraform init
```

Plan:

```
terraform plan
```

Apply:

```
terraform apply
```

Destroy:

```
terraform destroy
```

---

# 📌 Version

Neo VPS
Version 3
Multi-OS Infrastructure Engine
Golden AMI-Based Provisioning

---

Your move.
