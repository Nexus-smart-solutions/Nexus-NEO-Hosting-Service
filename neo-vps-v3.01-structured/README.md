
# Neo VPS V3 – Multi‑OS Provisioning Engine

## Overview
Neo VPS V3 is a Terraform‑based infrastructure engine designed to provision hosting environments on AWS.

Supports:
- AlmaLinux (Golden AMI)
- Ubuntu 22.04 (Golden AMI)
- cPanel
- CyberPanel
- DirectAdmin
- No Panel Option

---

## Project Structure

```
infra/
  ├── main.tf
  ├── variables.tf
  ├── outputs.tf
  ├── modules/
  ├── userdata/
  └── scripts/

docs/
.github/workflows/
```

---

## Provision Flow

1. Terraform initializes AWS provider
2. Network & Security modules deploy
3. EC2 instance launches from Golden AMI
4. User‑data installs selected panel
5. EIP attaches
6. DNS zone configures
7. Health checks validate deployment

---

## CI/CD

GitHub Actions pipeline should run:

- terraform fmt -check
- terraform init
- terraform validate
- terraform plan

⚠ Do NOT enable terraform apply in CI without control layer.

---

## Testing Locally

```
terraform init
terraform plan
terraform apply
```

Destroy:
```
terraform destroy
```

---

## Security Notes

- Do not commit tfstate
- Use IAM roles or GitHub Secrets
- Golden AMIs must be versioned
- Always test provisioning failures

---

## Version

V3 – Structured & Production‑Ready Layout
