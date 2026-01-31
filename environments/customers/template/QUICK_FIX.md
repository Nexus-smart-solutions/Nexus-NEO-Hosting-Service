# 🔧 Quick Fix Guide

## ❌ The Problem

The GitHub Actions workflow passes these variables:
```
-var="customer_domain=..."
-var="customer_email=..."     ← Different name!
-var="plan_tier=..."          ← Different name!
-var="client_id=..."          ← Missing!
```

But `variables.tf` expects:
```
variable "customer_domain" { }  ← ✅ Match
variable "admin_email" { }      ← ❌ Should be customer_email
variable "tier" { }             ← ❌ Should be plan_tier
# client_id is missing!         ← ❌ Not declared
```

---

## ✅ The Solution

Replace ALL template files with the fixed versions.

---

## 📂 Files to Replace

Replace these 6 files in `environments/customers/template/`:

1. ✅ **variables.tf** - Added all missing variables
2. ✅ **main.tf** - Updated to use correct variable names
3. ✅ **outputs.tf** - Complete outputs
4. ✅ **provider.tf** - AWS provider config
5. ✅ **backend.tf** - S3 backend template
6. ✅ **terraform.tfvars.example** - Example with correct names

---

## 🎯 Key Changes

### In `variables.tf`:

**Added these variables:**
```hcl
variable "customer_email" { }  # ← Was missing
variable "plan_tier" { }       # ← Was named "tier"
variable "client_id" { }       # ← Was missing
```

**Kept compatibility:**
```hcl
variable "admin_email" {
  default = ""  # Optional, falls back to customer_email
}

locals {
  # Use customer_email if admin_email not provided
  final_admin_email = var.admin_email != "" ? var.admin_email : var.customer_email
}
```

---

## 🚀 How to Apply

### Option 1: GitHub Web Interface

1. Go to: `environments/customers/template/`
2. Click on each file
3. Click **Edit** (pencil icon)
4. **Delete all content**
5. **Paste new content** from fixed files
6. **Commit changes**

### Option 2: Git Command Line

```bash
# Clone your repo
git clone https://github.com/Nexus-smart-solutions/Nexus-NEO-Hosting-Service.git
cd Nexus-NEO-Hosting-Service

# Copy fixed files
cp /path/to/complete-fix/* environments/customers/template/

# Commit and push
git add environments/customers/template/
git commit -m "fix: align template variables with workflow expectations"
git push origin main
```

---

## ✅ After Applying

The workflow will receive:
```
customer_domain  → variable "customer_domain" ✅
customer_email   → variable "customer_email"  ✅
plan_tier        → variable "plan_tier"       ✅
client_id        → variable "client_id"       ✅
```

All variables will be declared, no more errors! 🎉

---

## 🧪 Testing

After updating, test locally:

```bash
cd environments/customers/template

# Create test tfvars
cat > terraform.tfvars << EOF
customer_domain = "test.example.com"
customer_email  = "test@example.com"
plan_tier       = "standard"
client_id       = "test_001"
instance_type   = "t3.medium"
data_volume_size = 100
EOF

# Validate
terraform init -backend=false
terraform validate

# Should show: Success! ✅
```

---

## 📋 Checklist

- [ ] Replace `variables.tf`
- [ ] Replace `main.tf`
- [ ] Replace `outputs.tf`
- [ ] Replace `provider.tf`
- [ ] Replace `backend.tf`
- [ ] Replace `terraform.tfvars.example`
- [ ] Commit and push
- [ ] Test workflow

---

## 🆘 Still Having Issues?

Check the workflow file (`.github/workflows/provision-customer.yml`) to see exactly what variables it's passing with `-var=`.

All variable names in `variables.tf` must match what the workflow passes!
