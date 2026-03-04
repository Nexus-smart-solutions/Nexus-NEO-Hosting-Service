# 🚀 NEO APIs - Complete Reference

**Base URL:** `http://18.191.180.43:8080`  
**Terraform Organization:** `Neo_Platform`  
**Laravel Server:** `18.191.180.43:8080`

---

## 📦 Plans & Addons

> Returns available plans and marketplace addons before the customer orders a server.

### Get All Plans
```
GET http://18.191.180.43:8080/api/neo/plans
```

**Response:**
```json
{
  "plans": [
    { "slug": "core",  "price": 29,  "cpu": 1, "ram": "1GB",  "storage": "25GB",  "description": "Starter plan" },
    { "slug": "scale", "price": 79,  "cpu": 2, "ram": "4GB",  "storage": "80GB",  "description": "Business plan" },
    { "slug": "titan", "price": 199, "cpu": 4, "ram": "16GB", "storage": "200GB", "description": "Enterprise plan" }
  ]
}
```

---

### Get All Addons
```
GET http://18.191.180.43:8080/api/neo/addons
```

**Response:**
```json
{
  "addons": [
    { "slug": "storage-ebs-100", "name": "Extra 100GB Storage", "price": 10 },
    { "slug": "security-waf",    "name": "AWS WAF Protection",  "price": 25 },
    { "slug": "email-ses",       "name": "SES Email Service",   "price": 10 },
    { "slug": "cdn-cloudfront",  "name": "CloudFront CDN",      "price": 20 }
  ]
}
```

---

## 🌐 Domain

> Checks domain availability or registers an existing domain for a customer.

### Search for a Domain
```
POST http://18.191.180.43:8080/api/neo/domain/search
```

**Request Body:**
```json
{
  "domain": "acme-example.com"
}
```

**Response:**
```json
{
  "domain": "acme-example.com",
  "available": true,
  "suggestions": [
    "acme-example-shop.com",
    "acme-example-online.com"
  ]
}
```

---

### Register an Existing Domain
```
POST http://18.191.180.43:8080/api/neo/domain/existing
```

**Request Body:**
```json
{
  "domain": "acme-example.com",
  "customer_id": "acme-corp"
}
```

**Response:**
```json
{
  "domain": "acme-example.com",
  "customer_id": "acme-corp",
  "status": "accepted",
  "message": "Domain registered successfully"
}
```

---

## ⚙️ Provision

> The core service — creates a Workspace on Terraform Cloud, uploads all customer variables, and triggers the NEO Terraform scripts on AWS automatically.

### Create a New Server (Full Provision)
```
POST http://18.191.180.43:8080/api/neo/provision
```

**Request Body:**
```json
{
  "customer_id": "acme-corp",
  "customer_domain": "acme-example.com",
  "customer_email": "admin@acme-example.com",
  "plan_slug": "scale",
  "os_type": "almalinux-8",
  "control_panel": "cyberpanel",
  "aws_region": "us-east-2",
  "marketplace_addons": ["storage-ebs-100", "security-waf"],
  "ssh_key_name": "neo-deployment-key",
  "vpc_cidr": "10.0.0.0/16"
}
```

**Available Values:**
| Field | Options |
|---|---|
| `plan_slug` | `core`, `scale`, `titan` |
| `os_type` | `almalinux-8`, `ubuntu-22.04` |
| `control_panel` | `cpanel`, `cyberpanel`, `directadmin`, `none` |
| `aws_region` | Any AWS region e.g. `us-east-2` |

**Response:**
```json
{
  "order_id": "neo-acme-corp-1234567890",
  "workspace_id": "ws-xxxxxxxxxx",
  "run_id": "run-xxxxxxxxxx",
  "status": "provisioning",
  "customer_id": "acme-corp",
  "domain": "acme-example.com",
  "plan": "scale"
}
```

---

### Get Provision Status
```
GET http://18.191.180.43:8080/api/neo/provision/{orderId}/status
```

**Response:**
```json
{
  "order_id": "neo-acme-corp-1234567890",
  "status": "applied",
  "created_at": "2026-01-01T00:00:00Z"
}
```

**Possible Status Values:**
| Status | Meaning |
|---|---|
| `planning` | Terraform is planning |
| `planned` | Plan done, waiting for apply |
| `applying` | Terraform is applying |
| `applied` | Server is ready ✅ |
| `errored` | Something went wrong ❌ |
| `destroying` | Server is being destroyed |

---

### Destroy a Server
```
DELETE http://18.191.180.43:8080/api/neo/provision/{orderId}
```

**Response:**
```json
{
  "order_id": "neo-acme-corp-1234567890",
  "run_id": "run-xxxxxxxxxx",
  "status": "destroying"
}
```

---

## 🏗️ Terraform Workspaces

> Manages Terraform Cloud Workspaces — each customer has their own dedicated Workspace.

### List All Workspaces
```
GET http://18.191.180.43:8080/api/terraform/workspaces
```

### Create a Workspace
```
POST http://18.191.180.43:8080/api/terraform/workspaces
```

**Request Body:**
```json
{
  "name": "neo-acme-corp",
  "description": "Workspace for acme-corp",
  "auto_apply": false,
  "terraform_version": "1.6.0"
}
```

### Get a Workspace
```
GET http://18.191.180.43:8080/api/terraform/workspaces/{name}
```

### Update a Workspace
```
PATCH http://18.191.180.43:8080/api/terraform/workspaces/{workspaceId}
```

### Delete a Workspace
```
DELETE http://18.191.180.43:8080/api/terraform/workspaces/{workspaceId}
```

---

## ▶️ Terraform Runs

> Controls Terraform execution — plan, apply, cancel, destroy.

### List Runs for a Workspace
```
GET http://18.191.180.43:8080/api/terraform/workspaces/{workspaceId}/runs
```

### Trigger a New Run
```
POST http://18.191.180.43:8080/api/terraform/workspaces/{workspaceId}/runs
```

**Request Body:**
```json
{
  "message": "Deploy NEO v1.0",
  "auto_apply": false,
  "is_destroy": false
}
```

### Get Run Details
```
GET http://18.191.180.43:8080/api/terraform/runs/{runId}
```

### Apply a Run
```
POST http://18.191.180.43:8080/api/terraform/runs/{runId}/apply
```

**Request Body:**
```json
{
  "comment": "Approved by DevOps"
}
```

### Discard a Run
```
POST http://18.191.180.43:8080/api/terraform/runs/{runId}/discard
```

### Cancel a Run
```
POST http://18.191.180.43:8080/api/terraform/runs/{runId}/cancel
```

---

## 🔧 Terraform Variables

> Manages variables for each Workspace — such as region, os, panel, domain.

### List Variables
```
GET http://18.191.180.43:8080/api/terraform/workspaces/{workspaceId}/variables
```

### Create a Variable
```
POST http://18.191.180.43:8080/api/terraform/workspaces/{workspaceId}/variables
```

**Request Body:**
```json
{
  "key": "aws_region",
  "value": "us-east-2",
  "category": "terraform",
  "sensitive": false,
  "hcl": false,
  "description": "AWS deployment region"
}
```

**Category Options:**
| Category | Usage |
|---|---|
| `terraform` | Terraform variables (tfvars) |
| `env` | Environment variables |

### Update a Variable
```
PATCH http://18.191.180.43:8080/api/terraform/workspaces/{workspaceId}/variables/{variableId}
```

### Delete a Variable
```
DELETE http://18.191.180.43:8080/api/terraform/workspaces/{workspaceId}/variables/{variableId}
```

---

## 📌 Server Info

| Key | Value |
|---|---|
| **Laravel Server** | `18.191.180.43:8080` |
| **Terraform Org** | `Neo_Platform` |
| **Primary DNS** | `18.191.22.15` |
| **Secondary DNS** | `3.145.100.200` |
| **OS Options** | `almalinux-8`, `ubuntu-22.04` |
| **Panels** | `cpanel`, `cyberpanel`, `directadmin`, `none` |
| **Plans** | `core`, `scale`, `titan` |
| **Default Region** | `us-east-2` |
