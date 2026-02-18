أهلاً بك، للأسف **لا أستطيع رفع ملفات مباشرة** في الدردشة، لكن أقدر أرسل لك المحتوى الكامل للـ API Contract هنا، ويمكنك نسخه وحفظه بنفسك.

## 📋 **NEO-API-Contract**

```markdown
# Nexus NEO Hosting Service - API Contract v1.0

## Base URL
```
https://api.nexus-neo.com/v1
```

## Authentication
All API requests require an API key in the header:
```
Authorization: Bearer <your-api-key>
```

---

## 1. إنشاء سيرفر جديد
### `POST /api/v1/servers`

**Request Body:**
```json
{
  "customer_id": "acme-corp",
  "customer_domain": "example.com",
  "customer_email": "admin@example.com",
  "aws_region": "us-east-1",
  "environment": "production",
  "os_type": "almalinux",
  "os_version": "8",
  "control_panel": "cyberpanel",
  "instance_type": "t3.medium",
  "root_volume_size": 50,
  "data_volume_size": 100,
  "vpc_cidr": "10.0.0.0/16",
  "admin_cidrs": ["0.0.0.0/0"],
  "create_key_pair": false,
  "public_key": "",
  "existing_key_pair": "my-key",
  "backup_retention_days": 30,
  "enable_detailed_monitoring": true,
  "enable_cloudwatch_alarms": true,
  "enable_daily_snapshots": false,
  "snapshot_retention_days": 7,
  "allocate_eip": true,
  "enable_route53": false,
  "enable_mail_records": false,
  "enable_custom_nameservers": false,
  "ns1_ip": "",
  "ns2_ip": "",
  "sns_topic_arn": "",
  "alert_email": "admin@example.com",
  "slack_webhook": "",
  "cpu_high_threshold": 75,
  "disk_threshold": 80,
  "memory_threshold": 90,
  "enable_disk_alarm": true,
  "enable_memory_alarm": true,
  "create_dashboard": false,
  "create_dashboard_with_python": false,
  "use_custom_ami": false,
  "custom_ami_id": "",
  "panel_hostname": "panel.example.com",
  "tags": {
    "Department": "Marketing",
    "CostCenter": "12345"
  }
}
```

**Response 201 Created:**
```json
{
  "status": "success",
  "data": {
    "instance_id": "i-1234567890abcdef0",
    "instance_state": "running",
    "instance_type": "t3.medium",
    "availability_zone": "us-east-1a",
    "public_ip": "54.123.45.67",
    "private_ip": "10.0.1.45",
    "elastic_ip": "54.123.45.67",
    "control_panel": "cyberpanel",
    "control_panel_url": "https://54.123.45.67:8090",
    "panel_hostname": "panel.example.com",
    "ssh_command": "ssh root@54.123.45.67",
    "ssm_connect_command": "aws ssm start-session --target i-1234567890abcdef0",
    "root_volume_id": "vol-0123456789abcdef0",
    "data_volume_id": "vol-0123456789abcdef1",
    "backup_bucket_name": "example-com-backups-12345",
    "backup_bucket_arn": "arn:aws:s3:::example-com-backups-12345",
    "iam_role_arn": "arn:aws:iam::123456789012:role/neo-example-com-role",
    "instance_profile_arn": "arn:aws:iam::123456789012:instance-profile/neo-example-com-profile",
    "vpc_id": "vpc-0123456789abcdef0",
    "vpc_cidr": "10.0.0.0/16",
    "vpc_arn": "arn:aws:ec2:us-east-1:123456789012:vpc/vpc-0123456789abcdef0",
    "public_subnet_ids": ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"],
    "public_subnet_cidrs": ["10.0.1.0/24", "10.0.2.0/24"],
    "private_subnet_ids": ["subnet-0123456789abcdef2", "subnet-0123456789abcdef3"],
    "private_subnet_cidrs": ["10.0.10.0/24", "10.0.11.0/24"],
    "availability_zones": ["us-east-1a", "us-east-1b"],
    "internet_gateway_id": "igw-0123456789abcdef0",
    "nat_gateway_id": "nat-0123456789abcdef0",
    "nat_gateway_ip": "54.123.45.68",
    "public_route_table_id": "rtb-0123456789abcdef0",
    "private_route_table_id": "rtb-0123456789abcdef1",
    "s3_vpc_endpoint_id": "vpce-0123456789abcdef0",
    "security_group_id": "sg-0123456789abcdef0",
    "security_group_name": "neo-example-com-sg",
    "security_group_arn": "arn:aws:ec2:us-east-1:123456789012:security-group/sg-0123456789abcdef0",
    "route53_zone_id": "Z0123456789ABCDEF0",
    "sns_topic_arn": "arn:aws:sns:us-east-1:123456789012:neo-example-com-alerts",
    "dashboard_name": "neo-vps-example-com",
    "dashboard_url": "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=neo-vps-example-com",
    "alarm_names": [
      "neo-example-com-cpu-high",
      "neo-example-com-disk-high",
      "neo-example-com-memory-high"
    ],
    "alarm_count": 3,
    "cloudwatch_dashboard_url": "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1",
    "ec2_console_url": "https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:instanceId=i-1234567890abcdef0",
    "server_summary": {
      "domain": "example.com",
      "customer_id": "acme-corp",
      "control_panel": "cyberpanel",
      "instance_type": "t3.medium",
      "public_ip": "54.123.45.67",
      "panel_url": "https://54.123.45.67:8090",
      "ssh_command": "ssh root@54.123.45.67",
      "instance_id": "i-1234567890abcdef0",
      "backup_bucket": "example-com-backups-12345",
      "instance_state": "running"
    },
    "next_steps": "===================================\n🚀 Deployment Complete\n===================================\n\nServer IP: 54.123.45.67\nControl Panel: cyberpanel\n\nAccess Panel:\nhttps://54.123.45.67:8090\n\nSSH:\nssh root@54.123.45.67\n\nLogs:\ntail -f /var/log/neo-vps-setup.log\n\nNext:\n1. Point DNS to 54.123.45.67\n2. Configure SSL\n3. Harden firewall rules\n4. Setup monitoring alerts\n\n===================================\nNeo VPS v3.0\n==================================="
  },
  "metadata": {
    "request_id": "req_1234567890",
    "timestamp": "2026-02-18T15:30:00Z"
  }
}
```

---

## 2. جلب بيانات سيرفر
### `GET /api/v1/servers/{instance_id}`

**Response 200 OK:** نفس استجابة إنشاء سيرفر

---

## 3. قائمة السيرفرات
### `GET /api/v1/servers`

**Query Parameters:**
- `page` (default: 1)
- `limit` (default: 20)
- `customer_id` (optional)
- `environment` (optional)
- `state` (optional)

**Response 200 OK:**
```json
{
  "status": "success",
  "data": {
    "servers": [
      {
        "instance_id": "i-1234567890abcdef0",
        "customer_id": "acme-corp",
        "customer_domain": "example.com",
        "environment": "production",
        "public_ip": "54.123.45.67",
        "private_ip": "10.0.1.45",
        "instance_state": "running",
        "control_panel": "cyberpanel",
        "instance_type": "t3.medium",
        "created_at": "2026-02-18T15:30:00Z"
      }
    ],
    "total_count": 1,
    "page": 1,
    "total_pages": 1
  },
  "metadata": {
    "request_id": "req_1234567890",
    "timestamp": "2026-02-18T15:30:00Z"
  }
}
```

---

## 4. حذف سيرفر
### `DELETE /api/v1/servers/{instance_id}`

**Response 200 OK:**
```json
{
  "status": "success",
  "message": "Server i-1234567890abcdef0 is being terminated",
  "data": {
    "instance_id": "i-1234567890abcdef0",
    "state": "terminating"
  }
}
```

---

## 5. تحديث سيرفر
### `PUT /api/v1/servers/{instance_id}`

**Request Body:**
```json
{
  "instance_type": "t3.large",
  "enable_detailed_monitoring": true,
  "cpu_high_threshold": 85,
  "alert_email": "new-admin@example.com",
  "tags": {
    "Department": "Engineering"
  }
}
```

**Response 200 OK:** نفس استجابة إنشاء سيرفر

---

## 6. المناطق المتاحة
### `GET /api/v1/regions`

**Response 200 OK:**
```json
{
  "status": "success",
  "data": {
    "regions": [
      {"code": "us-east-1", "name": "US East (N. Virginia)"},
      {"code": "us-east-2", "name": "US East (Ohio)"},
      {"code": "us-west-1", "name": "US West (N. California)"},
      {"code": "us-west-2", "name": "US West (Oregon)"},
      {"code": "eu-west-1", "name": "EU (Ireland)"},
      {"code": "eu-central-1", "name": "EU (Frankfurt)"},
      {"code": "ap-southeast-1", "name": "Asia Pacific (Singapore)"},
      {"code": "ap-northeast-1", "name": "Asia Pacific (Tokyo)"}
    ]
  }
}
```

---

## 7. أنظمة التشغيل المتاحة
### `GET /api/v1/os-types`

**Response 200 OK:**
```json
{
  "status": "success",
  "data": {
    "os_types": [
      {
        "type": "almalinux",
        "versions": ["8", "9"],
        "name": "AlmaLinux",
        "default_version": "8"
      },
      {
        "type": "ubuntu",
        "versions": ["20.04", "22.04", "24.04"],
        "name": "Ubuntu",
        "default_version": "22.04"
      }
    ]
  }
}
```

---

## 8. لوحات التحكم المتاحة
### `GET /api/v1/control-panels`

**Response 200 OK:**
```json
{
  "status": "success",
  "data": {
    "control_panels": [
      {
        "id": "cpanel",
        "name": "cPanel",
        "ports": {
          "admin": 2087,
          "user": 2083,
          "webmail": 2096
        },
        "description": "Professional hosting control panel"
      },
      {
        "id": "cyberpanel",
        "name": "CyberPanel",
        "ports": {
          "admin": 8090
        },
        "description": "Open-source control panel with LiteSpeed"
      },
      {
        "id": "directadmin",
        "name": "DirectAdmin",
        "ports": {
          "admin": 2222
        },
        "description": "Lightweight and powerful control panel"
      },
      {
        "id": "none",
        "name": "No Control Panel",
        "ports": {},
        "description": "Bare server without any control panel"
      }
    ]
  }
}
```

---

## 9. أنواع الـ EC2 المتاحة
### `GET /api/v1/instance-types`

**Response 200 OK:**
```json
{
  "status": "success",
  "data": {
    "instance_types": [
      {
        "type": "t3.micro",
        "vcpu": 2,
        "memory_gb": 1,
        "description": "General purpose - entry level"
      },
      {
        "type": "t3.small",
        "vcpu": 2,
        "memory_gb": 2,
        "description": "General purpose - small"
      },
      {
        "type": "t3.medium",
        "vcpu": 2,
        "memory_gb": 4,
        "description": "General purpose - medium (recommended)"
      },
      {
        "type": "t3.large",
        "vcpu": 2,
        "memory_gb": 8,
        "description": "General purpose - large"
      },
      {
        "type": "t3.xlarge",
        "vcpu": 4,
        "memory_gb": 16,
        "description": "General purpose - xlarge"
      },
      {
        "type": "t3.2xlarge",
        "vcpu": 8,
        "memory_gb": 32,
        "description": "General purpose - 2xlarge"
      }
    ]
  }
}
```

---

## 10. DNS Records
### `GET /api/v1/servers/{instance_id}/dns`

**Response 200 OK:**
```json
{
  "status": "success",
  "data": {
    "zone_id": "Z0123456789ABCDEF0",
    "domain": "example.com",
    "records": [
      {
        "name": "example.com",
        "type": "A",
        "value": "54.123.45.67",
        "ttl": 300
      },
      {
        "name": "www.example.com",
        "type": "A",
        "value": "54.123.45.67",
        "ttl": 300
      },
      {
        "name": "mail.example.com",
        "type": "A",
        "value": "54.123.45.67",
        "ttl": 300
      },
      {
        "name": "example.com",
        "type": "MX",
        "value": "10 mail.example.com",
        "ttl": 3600
      },
      {
        "name": "example.com",
        "type": "TXT",
        "value": "v=spf1 mx a ip4:54.123.45.67 ~all",
        "ttl": 300
      }
    ]
  }
}
```

---

## 11. إضافة DNS Record
### `POST /api/v1/servers/{instance_id}/dns/records`

**Request Body:**
```json
{
  "name": "blog.example.com",
  "type": "A",
  "value": "54.123.45.67",
  "ttl": 300
}
```

**Response 201 Created:**
```json
{
  "status": "success",
  "message": "DNS record created successfully",
  "data": {
    "record_id": "record-12345",
    "name": "blog.example.com",
    "type": "A",
    "value": "54.123.45.67",
    "ttl": 300
  }
}
```

---

## 12. مقاييس السيرفر
### `GET /api/v1/servers/{instance_id}/metrics`

**Query Parameters:**
- `start_time` (ISO 8601, optional)
- `end_time` (ISO 8601, optional)
- `period` (seconds, default: 300, max: 86400)
- `metrics` (comma-separated, default: all)

**Response 200 OK:**
```json
{
  "status": "success",
  "data": {
    "instance_id": "i-1234567890abcdef0",
    "period": 300,
    "metrics": [
      {
        "timestamp": "2026-02-18T15:00:00Z",
        "cpu_utilization": 45.2,
        "disk_used_percent": 32.5,
        "memory_used_percent": 28.1,
        "network_in_bytes": 1250000,
        "network_out_bytes": 850000,
        "disk_read_bytes": 500000,
        "disk_write_bytes": 300000
      },
      {
        "timestamp": "2026-02-18T15:05:00Z",
        "cpu_utilization": 47.8,
        "disk_used_percent": 32.5,
        "memory_used_percent": 29.3,
        "network_in_bytes": 1320000,
        "network_out_bytes": 910000,
        "disk_read_bytes": 520000,
        "disk_write_bytes": 310000
      }
    ]
  }
}
```

---

## 13. الإنذارات (Alarms)
### `GET /api/v1/servers/{instance_id}/alarms`

**Response 200 OK:**
```json
{
  "status": "success",
  "data": {
    "alarms": [
      {
        "name": "neo-example-com-cpu-high",
        "state": "OK",
        "state_reason": "Threshold Crossed: 1 datapoint was not greater than the threshold (75.0).",
        "threshold": 75,
        "metric": "CPUUtilization",
        "namespace": "AWS/EC2",
        "comparison": "GreaterThanThreshold",
        "period": 300,
        "evaluation_periods": 2
      },
      {
        "name": "neo-example-com-disk-high",
        "state": "ALARM",
        "state_reason": "Threshold Crossed: 1 datapoint was greater than the threshold (80.0).",
        "threshold": 80,
        "metric": "disk_used_percent",
        "namespace": "CWAgent",
        "comparison": "GreaterThanThreshold",
        "period": 300,
        "evaluation_periods": 1
      }
    ]
  }
}
```

---

## 14. النسخ الاحتياطية
### `GET /api/v1/servers/{instance_id}/backups`

**Query Parameters:**
- `limit` (default: 10)
- `type` (daily/snapshot/all, default: all)

**Response 200 OK:**
```json
{
  "status": "success",
  "data": {
    "bucket": "example-com-backups-12345",
    "backups": [
      {
        "id": "backup-12345",
        "timestamp": "2026-02-18T03:00:00Z",
        "size_gb": 5.2,
        "type": "daily",
        "status": "completed",
        "volumes": ["vol-0123456789abcdef0", "vol-0123456789abcdef1"]
      },
      {
        "id": "backup-12344",
        "timestamp": "2026-02-17T03:00:00Z",
        "size_gb": 5.1,
        "type": "daily",
        "status": "completed",
        "volumes": ["vol-0123456789abcdef0", "vol-0123456789abcdef1"]
      }
    ],
    "total_count": 2
  }
}
```

---

## 15. إنشاء نسخة احتياطية
### `POST /api/v1/servers/{instance_id}/backups`

**Request Body:**
```json
{
  "type": "snapshot",
  "description": "Pre-update backup"
}
```

**Response 202 Accepted:**
```json
{
  "status": "success",
  "message": "Backup initiated successfully",
  "data": {
    "backup_id": "backup-12346",
    "status": "in_progress",
    "estimated_completion": "2026-02-18T15:35:00Z"
  }
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "status": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "customer_id",
        "issue": "Must be lowercase alphanumeric with hyphens only"
      },
      {
        "field": "customer_domain",
        "issue": "Must be a valid domain name"
      }
    ]
  },
  "metadata": {
    "request_id": "req_1234567890",
    "timestamp": "2026-02-18T15:30:00Z"
  }
}
```

### 401 Unauthorized
```json
{
  "status": "error",
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid or missing API key"
  },
  "metadata": {
    "request_id": "req_1234567890",
    "timestamp": "2026-02-18T15:30:00Z"
  }
}
```

### 404 Not Found
```json
{
  "status": "error",
  "error": {
    "code": "NOT_FOUND",
    "message": "Server with instance_id i-1234567890abcdef0 not found"
  },
  "metadata": {
    "request_id": "req_1234567890",
    "timestamp": "2026-02-18T15:30:00Z"
  }
}
```

### 429 Too Many Requests
```json
{
  "status": "error",
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded. Try again in 30 seconds"
  },
  "metadata": {
    "request_id": "req_1234567890",
    "timestamp": "2026-02-18T15:30:00Z"
  }
}
```

### 500 Internal Server Error
```json
{
  "status": "error",
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "An unexpected error occurred"
  },
  "metadata": {
    "request_id": "req_1234567890",
    "timestamp": "2026-02-18T15:30:00Z"
  }
}
```

---

## Rate Limiting

- **Rate Limit:** 100 requests per minute per API key
- **Headers:**
  - `X-RateLimit-Limit`: 100
  - `X-RateLimit-Remaining`: 95
  - `X-RateLimit-Reset`: 1624178400

---

## Validation Rules

| Field | Rules |
|-------|-------|
| `customer_id` | lowercase alphanumeric + hyphens only |
| `customer_domain` | valid domain name |
| `customer_email` | valid email format |
| `environment` | dev/staging/production |
| `os_type` | almalinux/ubuntu |
| `control_panel` | cpanel/cyberpanel/directadmin/none |
| `vpc_cidr` | valid CIDR block |
| `admin_cidrs` | array of valid CIDR blocks |
| `custom_ami_id` | must start with "ami-" if provided |
| `panel_hostname` | valid domain name if provided |

---

## Data Types

| Type | Description | Example |
|------|-------------|---------|
| `string` | Text value | `"example.com"` |
| `number` | Integer or float | `50` |
| `boolean` | true/false | `true` |
| `list(string)` | Array of strings | `["10.0.0.0/16"]` |
| `map(string)` | Key-value pairs | `{"key": "value"}` |
| `object` | Nested structure | `{"field": "value"}` |

---

## Environment Variables (for Backend)

```bash
# AWS Configuration
AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXX
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxx
AWS_REGION=us-east-1

# API Configuration
API_PORT=8080
API_TIMEOUT=30s
RATE_LIMIT=100

# Database
DATABASE_URL=postgres://user:pass@localhost:5432/neo
DATABASE_MAX_CONNECTIONS=20

# Redis (for caching)
REDIS_URL=redis://localhost:6379
REDIS_TTL=3600

# Monitoring
DEFAULT_ALERT_EMAIL=alerts@example.com
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/xxx/yyy/zzz
```

---

## Webhook Events

The API can send webhooks for async operations:

### Server Created
```json
{
  "event": "server.created",
  "timestamp": "2026-02-18T15:30:00Z",
  "data": {
    "instance_id": "i-1234567890abcdef0",
    "customer_id": "acme-corp",
    "state": "running"
  }
}
```

### Server Deleted
```json
{
  "event": "server.deleted",
  "timestamp": "2026-02-18T15:30:00Z",
  "data": {
    "instance_id": "i-1234567890abcdef0",
    "customer_id": "acme-corp"
  }
}
```

### Alarm Triggered
```json
{
  "event": "alarm.triggered",
  "timestamp": "2026-02-18T15:30:00Z",
  "data": {
    "alarm_name": "neo-example-com-cpu-high",
    "instance_id": "i-1234567890abcdef0",
    "state": "ALARM",
    "metric": "CPUUtilization",
    "value": 85.2,
    "threshold": 75
  }
}
```

### Backup Completed
```json
{
  "event": "backup.completed",
  "timestamp": "2026-02-18T15:35:00Z",
  "data": {
    "backup_id": "backup-12346",
    "instance_id": "i-1234567890abcdef0",
    "size_gb": 5.2,
    "status": "completed"
  }
}
```

---

## SDK Examples

### Python
```python
import requests

API_KEY = "your-api-key"
BASE_URL = "https://api.nexus-neo.com/v1"

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}

# Create server
response = requests.post(
    f"{BASE_URL}/servers",
    headers=headers,
    json={
        "customer_id": "acme-corp",
        "customer_domain": "example.com",
        "customer_email": "admin@example.com"
    }
)

server = response.json()
print(f"Server created: {server['data']['instance_id']}")
```

### Node.js
```javascript
const axios = require('axios');

const API_KEY = 'your-api-key';
const BASE_URL = 'https://api.nexus-neo.com/v1';

const api = axios.create({
  baseURL: BASE_URL,
  headers: {
    'Authorization': `Bearer ${API_KEY}`,
    'Content-Type': 'application/json'
  }
});

// List servers
const { data } = await api.get('/servers');
console.log(`Found ${data.data.total_count} servers`);
```

### Go
```go
package main

import (
    "bytes"
    "encoding/json"
    "fmt"
    "net/http"
)

func main() {
    apiKey := "your-api-key"
    baseURL := "https://api.nexus-neo.com/v1"

    // Create server
    serverData := map[string]interface{}{
        "customer_id":    "acme-corp",
        "customer_domain": "example.com",
        "customer_email":  "admin@example.com",
    }

    jsonData, _ := json.Marshal(serverData)
    
    req, _ := http.NewRequest("POST", baseURL+"/servers", bytes.NewBuffer(jsonData))
    req.Header.Set("Authorization", "Bearer "+apiKey)
    req.Header.Set("Content-Type", "application/json")

    client := &http.Client{}
    resp, _ := client.Do(req)
    defer resp.Body.Close()
    
    fmt.Println("Status:", resp.Status)
}
```

---

## Changelog

### v1.0.0 (2026-02-18)
- Initial release
- Complete server management API
- DNS management
- Monitoring and alerts
- Backup management
- Webhook support

---

## Support

- **Documentation:** https://docs.nexus-neo.com
- **API Status:** https://status.nexus-neo.com
- **Email:** api-support@nexus-neo.com
- **Discord:** https://discord.gg/nexus-neo
```

---

## 📥 **لحفظ الملف:**

### **طريقة 1: نسخ ولصق**
1. حدد كل المحتوى أعلاه (Ctrl+A)
2. انسخه (Ctrl+C)
3. افتح محرر نصوص (VS Code, Notepad++, Sublime)
4. الصق المحتوى (Ctrl+V)
5. احفظ الملف باسم `API-Contract.md`

### **طريقة 2: استخدام سطر الأوامر**
```bash
# أنشئ الملف
cat > API-Contract.md << 'EOF'
[الصق المحتوى هنا]
EOF
```

### **طريقة 3: رفع على GitHub**
```bash
# في مجلد المشروع
mkdir -p docs
# أنشئ الملف docs/API-Contract.md بالمحتوى أعلاه
git add docs/API-Contract.md
git commit -m "docs: add complete API contract"
git push
```

**الملف جاهز!** سلمه لفريق الـ Backend وخلهم يبدأوا الشغل 🚀✨
