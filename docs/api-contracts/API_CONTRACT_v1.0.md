# API Contract Specification v1.0

## Overview

This document defines the API contract between the **Backend Application** and the **Infrastructure Provisioning System** (GitHub Actions).

---

## Endpoint

**URL:** `https://api.github.com/repos/{owner}/{repo}/dispatches`

**Method:** `POST`

**Authentication:** GitHub Personal Access Token (PAT) with `repo` scope

---

## Request Format

### Headers

```http
POST /repos/{owner}/{repo}/dispatches HTTP/1.1
Host: api.github.com
Accept: application/vnd.github+json
Authorization: Bearer {GITHUB_TOKEN}
Content-Type: application/json
```

### Body Structure

```json
{
  "event_type": "provision_customer",
  "client_payload": {
    "domain": "string",
    "email": "string",
    "tier": "string",
    "client_id": "string",
    "transaction_id": "string",
    "features": {
      "instance_type": "string",
      "storage_gb": "integer",
      "bandwidth_gb": "integer",
      "email_accounts": "integer",
      "databases": "integer",
      "ssl_enabled": "boolean",
      "backups_enabled": "boolean"
    },
    "metadata": {
      "plan_name": "string",
      "billing_cycle": "string",
      "amount_paid": "number",
      "currency": "string",
      "customer_ip": "string",
      "signup_date": "string (ISO 8601)"
    }
  }
}
```

---

## Field Definitions

### Required Fields

| Field | Type | Description | Example | Validation |
|-------|------|-------------|---------|------------|
| `event_type` | string | Event identifier (fixed) | `"provision_customer"` | Must be exactly `"provision_customer"` |
| `domain` | string | Customer domain name | `"example.com"` | Valid domain format, no subdomain |
| `email` | string | Customer email | `"customer@example.com"` | Valid email format |
| `tier` | string | Hosting tier | `"basic"`, `"standard"`, `"premium"` | One of: basic, standard, premium |
| `client_id` | string | Unique customer identifier | `"cust_abc123xyz"` | Alphanumeric, max 50 chars |

### Optional Fields

| Field | Type | Description | Default | Validation |
|-------|------|-------------|---------|------------|
| `transaction_id` | string | Payment transaction ID | `null` | Alphanumeric, max 100 chars |
| `features.*` | object | Feature configuration | tier defaults | See feature definitions |
| `metadata.*` | object | Additional metadata | `{}` | See metadata definitions |

---

## Tier Configurations

### Basic Tier

```json
{
  "tier": "basic",
  "features": {
    "instance_type": "t3.micro",
    "storage_gb": 50,
    "bandwidth_gb": 100,
    "email_accounts": 10,
    "databases": 5,
    "ssl_enabled": true,
    "backups_enabled": true
  }
}
```

**Pricing:** $35/month

---

### Standard Tier

```json
{
  "tier": "standard",
  "features": {
    "instance_type": "t3.medium",
    "storage_gb": 100,
    "bandwidth_gb": 500,
    "email_accounts": 50,
    "databases": 10,
    "ssl_enabled": true,
    "backups_enabled": true
  }
}
```

**Pricing:** $85/month

---

### Premium Tier

```json
{
  "tier": "premium",
  "features": {
    "instance_type": "t3.large",
    "storage_gb": 200,
    "bandwidth_gb": 1000,
    "email_accounts": 100,
    "databases": 25,
    "ssl_enabled": true,
    "backups_enabled": true
  }
}
```

**Pricing:** $150/month

---

## Complete Request Examples

### Example 1: Basic Tier Customer

```json
{
  "event_type": "provision_customer",
  "client_payload": {
    "domain": "smallbusiness.com",
    "email": "owner@smallbusiness.com",
    "tier": "basic",
    "client_id": "cust_sb001",
    "transaction_id": "txn_1234567890",
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
      "plan_name": "Basic Hosting Plan",
      "billing_cycle": "monthly",
      "amount_paid": 35.00,
      "currency": "USD",
      "customer_ip": "203.0.113.45",
      "signup_date": "2024-01-29T14:30:00Z"
    }
  }
}
```

### Example 2: Standard Tier Customer

```json
{
  "event_type": "provision_customer",
  "client_payload": {
    "domain": "techstartup.io",
    "email": "admin@techstartup.io",
    "tier": "standard",
    "client_id": "cust_ts002",
    "transaction_id": "txn_0987654321",
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
      "plan_name": "Standard Hosting Plan",
      "billing_cycle": "annual",
      "amount_paid": 900.00,
      "currency": "USD",
      "customer_ip": "198.51.100.23",
      "signup_date": "2024-01-29T15:00:00Z"
    }
  }
}
```

### Example 3: Premium Tier Customer

```json
{
  "event_type": "provision_customer",
  "client_payload": {
    "domain": "enterprise-corp.com",
    "email": "it@enterprise-corp.com",
    "tier": "premium",
    "client_id": "cust_ec003",
    "transaction_id": "txn_premium123",
    "features": {
      "instance_type": "t3.large",
      "storage_gb": 300,
      "bandwidth_gb": 2000,
      "email_accounts": 150,
      "databases": 50,
      "ssl_enabled": true,
      "backups_enabled": true
    },
    "metadata": {
      "plan_name": "Premium Hosting Plan",
      "billing_cycle": "monthly",
      "amount_paid": 150.00,
      "currency": "USD",
      "customer_ip": "192.0.2.100",
      "signup_date": "2024-01-29T16:00:00Z"
    }
  }
}
```

### Example 4: Minimal Request (Required Fields Only)

```json
{
  "event_type": "provision_customer",
  "client_payload": {
    "domain": "minimal-example.com",
    "email": "user@minimal-example.com",
    "tier": "basic",
    "client_id": "cust_min004"
  }
}
```

---

## Response Format

### Success Response (HTTP 204)

GitHub API returns **204 No Content** on successful dispatch.

```http
HTTP/1.1 204 No Content
Status: 204 No Content
```

**Note:** GitHub Actions workflow will run asynchronously. Status must be checked separately.

---

### Error Responses

#### 401 Unauthorized

```json
{
  "message": "Bad credentials",
  "documentation_url": "https://docs.github.com/rest"
}
```

**Cause:** Invalid or expired GitHub token

---

#### 404 Not Found

```json
{
  "message": "Not Found",
  "documentation_url": "https://docs.github.com/rest"
}
```

**Cause:** Repository doesn't exist or token lacks access

---

#### 422 Unprocessable Entity

```json
{
  "message": "Validation Failed",
  "errors": [
    {
      "resource": "RepositoryDispatch",
      "code": "custom",
      "message": "event_type is required"
    }
  ]
}
```

**Cause:** Invalid payload structure

---

## Validation Rules

### Domain Validation

```regex
^(?!:\/\/)([a-zA-Z0-9-_]+\.)*[a-zA-Z0-9][a-zA-Z0-9-_]+\.[a-zA-Z]{2,11}?$
```

**Valid:**
- `example.com`
- `my-site.io`
- `website123.co.uk`

**Invalid:**
- `subdomain.example.com` (no subdomains)
- `example` (must have TLD)
- `example..com` (double dots)
- `http://example.com` (no protocol)

---

### Email Validation

```regex
^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
```

**Valid:**
- `user@example.com`
- `admin+test@site.co.uk`
- `contact_us@my-site.io`

**Invalid:**
- `invalid@` (no domain)
- `@example.com` (no username)
- `user@.com` (invalid domain)

---

### Tier Validation

**Allowed values:**
- `basic`
- `standard`
- `premium`

**Case:** Case-sensitive, must be lowercase

---

### Client ID Validation

```regex
^[a-zA-Z0-9_-]{1,50}$
```

**Valid:**
- `cust_123`
- `customer-abc-xyz`
- `USER_001`

**Invalid:**
- `customer@123` (special characters)
- `a` (too short if needed)
- `very-long-id-that-exceeds-fifty-characters-limit` (too long)

---

## Workflow Status Tracking

After dispatching the event, the backend should track workflow status.

### Check Workflow Runs

```http
GET /repos/{owner}/{repo}/actions/runs
```

**Filter by:**
- `event: repository_dispatch`
- `created: >DISPATCH_TIME`

### Response

```json
{
  "workflow_runs": [
    {
      "id": 123456789,
      "status": "completed",
      "conclusion": "success",
      "html_url": "https://github.com/owner/repo/actions/runs/123456789"
    }
  ]
}
```

**Possible statuses:**
- `queued` - Waiting to run
- `in_progress` - Currently running
- `completed` - Finished

**Possible conclusions (when completed):**
- `success` - Provisioning successful
- `failure` - Provisioning failed
- `cancelled` - Workflow cancelled
- `timed_out` - Workflow timeout

---

## Error Handling

### Validation Errors (Before API Call)

Backend should validate payload **before** calling GitHub API:

```javascript
// Example validation (JavaScript)
function validatePayload(payload) {
  const errors = [];
  
  // Required fields
  if (!payload.domain) {
    errors.push("domain is required");
  }
  if (!payload.email) {
    errors.push("email is required");
  }
  if (!payload.tier) {
    errors.push("tier is required");
  }
  if (!payload.client_id) {
    errors.push("client_id is required");
  }
  
  // Tier validation
  const validTiers = ['basic', 'standard', 'premium'];
  if (payload.tier && !validTiers.includes(payload.tier)) {
    errors.push(`tier must be one of: ${validTiers.join(', ')}`);
  }
  
  // Email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (payload.email && !emailRegex.test(payload.email)) {
    errors.push("email format is invalid");
  }
  
  return errors;
}
```

---

### Provisioning Errors (Workflow Failures)

If workflow fails, backend should:

1. **Check workflow logs** for error details
2. **Notify customer** of failure
3. **Log error** for investigation
4. **Retry** if appropriate (network issues)
5. **Escalate** if persistent failure

---

## Rate Limiting

GitHub API has rate limits:

- **Authenticated requests:** 5,000 per hour
- **Repository dispatch:** No specific limit documented

**Best practices:**
- Implement retry with exponential backoff
- Monitor rate limit headers
- Queue requests if near limit

---

## Security Considerations

### Token Security

- ✅ Use GitHub PAT with minimal scope (`repo` only)
- ✅ Rotate tokens regularly (every 90 days)
- ✅ Store token in secure secret manager
- ✅ Never log token values
- ✅ Use separate tokens for prod/staging

### Payload Security

- ✅ Validate all inputs server-side
- ✅ Sanitize domain/email before use
- ✅ Limit payload size (< 64 KB)
- ✅ Log all API calls for audit
- ✅ Implement HMAC signature (optional)

---

## Testing

### Test Payload

Use this for testing:

```json
{
  "event_type": "provision_customer",
  "client_payload": {
    "domain": "test-customer.com",
    "email": "test@example.com",
    "tier": "basic",
    "client_id": "test_001",
    "transaction_id": "test_txn_123",
    "metadata": {
      "plan_name": "Test Plan",
      "billing_cycle": "test",
      "amount_paid": 0.00,
      "currency": "USD",
      "customer_ip": "127.0.0.1",
      "signup_date": "2024-01-29T00:00:00Z"
    }
  }
}
```

### cURL Example

```bash
curl -X POST \
  https://api.github.com/repos/OWNER/REPO/dispatches \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer YOUR_GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "provision_customer",
    "client_payload": {
      "domain": "test-customer.com",
      "email": "test@example.com",
      "tier": "basic",
      "client_id": "test_001"
    }
  }'
```

---

## Implementation Checklist

### Backend Team Tasks

- [ ] Implement payload validation
- [ ] Add GitHub API client
- [ ] Store GitHub token securely
- [ ] Implement error handling
- [ ] Add retry logic
- [ ] Log all API calls
- [ ] Monitor workflow status
- [ ] Handle failures gracefully
- [ ] Test with staging environment
- [ ] Document integration

### DevOps Team Tasks (Completed)

- [x] Define API contract
- [x] Create GitHub Actions workflow
- [x] Configure secrets
- [x] Test workflow manually
- [x] Document workflow behavior
- [x] Provide testing examples

---

## Support

### Questions?

- 📖 [GitHub Docs - Repository Dispatch](https://docs.github.com/en/rest/repos/repos#create-a-repository-dispatch-event)
- 💬 Contact DevOps team
- 🐛 Report issues

---

## Changelog

### Version 1.0 (2024-01-29)
- Initial API contract specification
- Defined payload structure
- Added tier configurations
- Included validation rules
- Provided testing examples
