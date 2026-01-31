# Test Payloads

Collection of test payloads for various scenarios.

---

## Valid Payloads

### 1. Basic Tier - Minimal

**File:** `test-basic-minimal.json`

```json
{
  "event_type": "provision_customer",
  "client_payload": {
    "domain": "basic-test.com",
    "email": "test@basic-test.com",
    "tier": "basic",
    "client_id": "test_basic_001"
  }
}
```

**Use case:** Simplest valid payload with required fields only.

---

### 2. Basic Tier - Complete

**File:** `test-basic-complete.json`

```json
{
  "event_type": "provision_customer",
  "client_payload": {
    "domain": "complete-basic.com",
    "email": "admin@complete-basic.com",
    "tier": "basic",
    "client_id": "test_basic_002",
    "transaction_id": "txn_basic_123",
    "features": {
      "instance_type": "t3.micro",
      "storage_gb": 50,
      "bandwidth_gb": 100,
      "email_accounts": 10,
      "databases": 5,
      "ssl_enabled": true,
      "backups_enabled": true
    },
    "metadata": {
      "plan_name": "Basic Starter Plan",
      "billing_cycle": "monthly",
      "amount_paid": 35.00,
      "currency": "USD",
      "customer_ip": "203.0.113.10",
      "signup_date": "2024-01-29T10:00:00Z"
    }
  }
}
```

**Use case:** Complete payload with all optional fields.

---

### 3. Standard Tier - Default

**File:** `test-standard-default.json`

```json
{
  "event_type": "provision_customer",
  "client_payload": {
    "domain": "standard-business.io",
    "email": "contact@standard-business.io",
    "tier": "standard",
    "client_id": "test_std_001",
    "transaction_id": "txn_std_456"
  }
}
```

**Use case:** Standard tier with default configurations.

---

### 4. Standard Tier - Custom Features

**File:** `test-standard-custom.json`

```json
{
  "event_type": "provision_customer",
  "client_payload": {
    "domain": "custom-standard.net",
    "email": "admin@custom-standard.net",
    "tier": "standard",
    "client_id": "test_std_002",
    "transaction_id": "txn_std_789",
    "features": {
      "instance_type": "t3.medium",
      "storage_gb": 150,
      "bandwidth_gb": 750,
      "email_accounts": 75,
      "databases": 15,
      "ssl_enabled": true,
      "backups_enabled": true
    },
    "metadata": {
      "plan_name": "Standard Plus Plan",
      "billing_cycle": "annual",
      "amount_paid": 900.00,
      "currency": "USD",
      "customer_ip": "198.51.100.50",
      "signup_date": "2024-01-29T11:30:00Z"
    }
  }
}
```

**Use case:** Standard tier with custom feature overrides.

---

### 5. Premium Tier - Enterprise

**File:** `test-premium-enterprise.json`

```json
{
  "event_type": "provision_customer",
  "client_payload": {
    "domain": "enterprise-corp.com",
    "email": "it-admin@enterprise-corp.com",
    "tier": "premium",
    "client_id": "test_prem_001",
    "transaction_id": "txn_prem_enterprise",
    "features": {
      "instance_type": "t3.large",
      "storage_gb": 300,
      "bandwidth_gb": 2000,
      "email_accounts": 200,
      "databases": 50,
      "ssl_enabled": true,
      "backups_enabled": true
    },
    "metadata": {
      "plan_name": "Premium Enterprise Plan",
      "billing_cycle": "annual",
      "amount_paid": 1620.00,
      "currency": "USD",
      "customer_ip": "192.0.2.100",
      "signup_date": "2024-01-29T13:00:00Z"
    }
  }
}
```

**Use case:** Large enterprise customer with maximum resources.

---

## Invalid Payloads (For Testing Error Handling)

### 6. Missing Required Field - domain

**File:** `test-error-missing-domain.json`

```json
{
  "event_type": "provision_customer",
  "client_payload": {
    "email": "test@example.com",
    "tier": "basic",
    "client_id": "test_err_001"
  }
}
```

**Expected Error:** Validation failure - "domain is required"

---

### 7. Missing Required Field - email

**File:** `test-error-missing-email.json`

```json
{
  "event_type": "provision_customer",
  "client_payload": {
    "domain": "test-error.com",
    "tier": "basic",
    "client_id": "test_err_002"
  }
}
```

**Expected Error:** Validation failure - "email is required"

---

### 8. Invalid Tier

**File:** `test-error-invalid-tier.json`

```json
{
  "event_type": "provision_customer",
  "client_payload": {
    "domain": "invalid-tier.com",
    "email": "test@invalid-tier.com",
    "tier": "ultimate",
    "client_id": "test_err_003"
  }
}
```

**Expected Error:** Validation failure - "tier must be one of: basic, standard, premium"

---

### 9. Invalid Domain Format

**File:** `test-error-invalid-domain.json`

```json
{
  "event_type": "provision_customer",
  "client_payload": {
    "domain": "http://example.com",
    "email": "test@example.com",
    "tier": "basic",
    "client_id": "test_err_004"
  }
}
```

**Expected Error:** Validation failure - "domain format is invalid"

---

### 10. Invalid Email Format

**File:** `test-error-invalid-email.json`

```json
{
  "event_type": "provision_customer",
  "client_payload": {
    "domain": "test-email.com",
    "email": "not-an-email",
    "tier": "basic",
    "client_id": "test_err_005"
  }
}
```

**Expected Error:** Validation failure - "email format is invalid"

---

### 11. Invalid Event Type

**File:** `test-error-wrong-event.json`

```json
{
  "event_type": "delete_customer",
  "client_payload": {
    "domain": "test.com",
    "email": "test@test.com",
    "tier": "basic",
    "client_id": "test_err_006"
  }
}
```

**Expected Error:** Workflow not triggered (event type mismatch)

---

### 12. Storage Too Large

**File:** `test-error-storage-limit.json`

```json
{
  "event_type": "provision_customer",
  "client_payload": {
    "domain": "huge-storage.com",
    "email": "test@huge-storage.com",
    "tier": "basic",
    "client_id": "test_err_007",
    "features": {
      "storage_gb": 5000
    }
  }
}
```

**Expected Error:** Validation failure - "storage_gb exceeds maximum (1000)"

---

### 13. Invalid Instance Type

**File:** `test-error-invalid-instance.json`

```json
{
  "event_type": "provision_customer",
  "client_payload": {
    "domain": "wrong-instance.com",
    "email": "test@wrong-instance.com",
    "tier": "basic",
    "client_id": "test_err_008",
    "features": {
      "instance_type": "m5.large"
    }
  }
}
```

**Expected Error:** Validation failure - "instance_type not in allowed list"

---

## Testing Instructions

### Using cURL

```bash
# Test valid payload
curl -X POST \
  https://api.github.com/repos/OWNER/REPO/dispatches \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Content-Type: application/json" \
  -d @test-basic-minimal.json

# Test invalid payload (should fail validation)
curl -X POST \
  https://api.github.com/repos/OWNER/REPO/dispatches \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Content-Type: application/json" \
  -d @test-error-missing-domain.json
```

### Using Python

```python
import json
import requests

GITHUB_TOKEN = "your_token_here"
OWNER = "your_username"
REPO = "AWS-STRUCTURE-FRAMWORK"

def dispatch_event(payload_file):
    with open(payload_file, 'r') as f:
        payload = json.load(f)
    
    url = f"https://api.github.com/repos/{OWNER}/{REPO}/dispatches"
    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Content-Type": "application/json"
    }
    
    response = requests.post(url, headers=headers, json=payload)
    
    if response.status_code == 204:
        print(f"✅ Success: {payload_file}")
    else:
        print(f"❌ Failed: {payload_file}")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")

# Test all valid payloads
test_files = [
    "test-basic-minimal.json",
    "test-standard-default.json",
    "test-premium-enterprise.json"
]

for test_file in test_files:
    dispatch_event(test_file)
```

### Using JavaScript/Node.js

```javascript
const fs = require('fs');
const fetch = require('node-fetch');

const GITHUB_TOKEN = process.env.GITHUB_TOKEN;
const OWNER = 'your_username';
const REPO = 'AWS-STRUCTURE-FRAMWORK';

async function dispatchEvent(payloadFile) {
  const payload = JSON.parse(fs.readFileSync(payloadFile, 'utf8'));
  
  const url = `https://api.github.com/repos/${OWNER}/${REPO}/dispatches`;
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Accept': 'application/vnd.github+json',
      'Authorization': `Bearer ${GITHUB_TOKEN}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(payload)
  });
  
  if (response.status === 204) {
    console.log(`✅ Success: ${payloadFile}`);
  } else {
    console.log(`❌ Failed: ${payloadFile}`);
    console.log(`Status: ${response.status}`);
    console.log(`Response: ${await response.text()}`);
  }
}

// Test
const testFiles = [
  'test-basic-minimal.json',
  'test-standard-default.json',
  'test-premium-enterprise.json'
];

testFiles.forEach(file => dispatchEvent(file));
```

---

## Validation Testing

### Test Checklist

- [ ] Valid payloads trigger workflow successfully
- [ ] Missing required fields return appropriate errors
- [ ] Invalid tier values are rejected
- [ ] Invalid domain formats are rejected
- [ ] Invalid email formats are rejected
- [ ] Storage limits are enforced
- [ ] Instance type whitelist is enforced
- [ ] Wrong event_type doesn't trigger workflow
- [ ] All tier configurations work correctly
- [ ] Metadata fields are optional and work

---

## Expected Workflow Behavior

### For Valid Payloads

1. GitHub returns **204 No Content**
2. Workflow is triggered asynchronously
3. Workflow creates infrastructure
4. Email is sent to customer
5. Workflow completes with **success**

### For Invalid Payloads

1. If validation fails **before** API call:
   - Backend returns error to user
   - No API call is made
   - No workflow is triggered

2. If GitHub API rejects payload:
   - GitHub returns **422 Unprocessable Entity**
   - Backend logs error
   - User is notified of failure

3. If workflow fails during execution:
   - Workflow status: **failure**
   - Backend checks workflow status
   - Customer is notified
   - Support team is alerted

---

## Notes

- All test files use `test-` prefix to distinguish from production
- Invalid payloads are prefixed with `test-error-`
- Transaction IDs use `txn_test_` or `txn_*` format
- Test customer IDs use `test_*` prefix
- Test domains should use reserved test TLDs (`.test`, `.example`)

---

## Cleanup

After testing, clean up test infrastructure:

```bash
# List all test deployments
cd environments/customers
ls -d test-*

# Destroy test deployment
cd test-basic-001
terraform destroy -auto-approve
```
