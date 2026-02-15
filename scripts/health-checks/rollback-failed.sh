#!/bin/bash
# ================================================================
# ROLLBACK FAILED PROVISIONING
# ================================================================
# Automatically destroys failed infrastructure
# Called when health check fails
# ================================================================

set -euo pipefail

# Configuration
CUSTOMER_DOMAIN="${1:-}"
REASON="${2:-Health check failed}"

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_error() {
    echo -e "${RED}[✗]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1" >&2
}

# Validate arguments
if [[ -z "$CUSTOMER_DOMAIN" ]]; then
    log_error "Usage: $0 <customer_domain> [reason]"
    exit 1
fi

CUSTOMER_DIR="/terraform/customers/$CUSTOMER_DOMAIN"

if [[ ! -d "$CUSTOMER_DIR" ]]; then
    log_error "Customer directory not found: $CUSTOMER_DIR"
    exit 1
fi

echo ""
echo "========================================="
echo "  ROLLBACK FAILED PROVISIONING"
echo "========================================="
echo "Domain: $CUSTOMER_DOMAIN"
echo "Reason: $REASON"
echo "========================================="
echo ""

log_warning "Starting rollback process..."
log_warning "This will destroy all infrastructure for $CUSTOMER_DOMAIN"

# Wait 10 seconds
log_warning "Waiting 10 seconds... (Ctrl+C to cancel)"
sleep 10

# Change to customer directory
cd "$CUSTOMER_DIR" || exit 1

# Terraform destroy
log_warning "Running terraform destroy..."

if terraform destroy -auto-approve -no-color; then
    echo ""
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED}  ROLLBACK COMPLETED${NC}"
    echo -e "${RED}=========================================${NC}"
    echo "Domain: $CUSTOMER_DOMAIN"
    echo "All resources have been destroyed"
    echo -e "${RED}=========================================${NC}"
    echo ""
    
    # Update status in database (if backend API exists)
    if command -v curl &> /dev/null && [[ -n "${API_ENDPOINT:-}" ]]; then
        curl -X POST "$API_ENDPOINT/provisioning/rollback" \
            -H "Content-Type: application/json" \
            -d "{\"domain\": \"$CUSTOMER_DOMAIN\", \"reason\": \"$REASON\"}" \
            2>/dev/null || true
    fi
    
    exit 0
else
    log_error "Terraform destroy failed!"
    log_error "Manual cleanup may be required"
    exit 1
fi
