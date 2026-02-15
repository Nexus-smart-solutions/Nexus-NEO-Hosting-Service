#!/bin/bash
# ================================================================
# PROVISIONING WITH HEALTH CHECK & ROLLBACK
# ================================================================
# Integrates health check into provisioning flow
# ================================================================

set -euo pipefail

DOMAIN="${1:-}"
EMAIL="${2:-}"
PANEL="${3:-cyberpanel}"
OS="${4:-almalinux-8}"
PLAN="${5:-standard}"

# Validate
if [[ -z "$DOMAIN" ]] || [[ -z "$EMAIL" ]]; then
    echo "Usage: $0 <domain> <email> [panel] [os] [plan]"
    exit 1
fi

CUSTOMER_DIR="/terraform/customers/$DOMAIN"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Starting provisioning with health check for $DOMAIN..."

# Step 1: Run normal provisioning
if ! "$SCRIPTS_DIR/../automation/provision-customer.sh" \
    --domain "$DOMAIN" \
    --email "$EMAIL" \
    --panel "$PANEL" \
    --os "$OS" \
    --plan "$PLAN"; then
    echo "Provisioning failed!"
    exit 1
fi

# Step 2: Get server IP
cd "$CUSTOMER_DIR"
SERVER_IP=$(terraform output -raw elastic_ip 2>/dev/null || echo "")

if [[ -z "$SERVER_IP" ]]; then
    echo "Failed to get server IP from Terraform output"
    exit 1
fi

echo "Server IP: $SERVER_IP"
echo "Running health check..."

# Step 3: Run health check
if "$SCRIPTS_DIR/health-checks/check-provisioning.sh" "$DOMAIN" "$PANEL" "$SERVER_IP"; then
    echo ""
    echo "========================================="
    echo "  ✓ PROVISIONING SUCCESSFUL"
    echo "========================================="
    echo "Domain:    $DOMAIN"
    echo "Panel:     $PANEL"
    echo "Server IP: $SERVER_IP"
    echo "========================================="
    exit 0
else
    echo ""
    echo "========================================="
    echo "  ✗ HEALTH CHECK FAILED"
    echo "========================================="
    echo "Initiating rollback..."
    echo ""
    
    # Step 4: Rollback
    "$SCRIPTS_DIR/health-checks/rollback-failed.sh" "$DOMAIN" "Health check failed"
    
    exit 1
fi
