#!/bin/bash
STATE_DIR="/var/neo/states"
mkdir -p "$STATE_DIR"

track_state() {
  local domain="$1"
  local state="$2"
  local message="$3"
  
  local state_file="$STATE_DIR/${domain}.json"
  
  cat > "$state_file" << EOF
{
  "domain": "$domain",
  "state": "$state",
  "message": "$message",
  "timestamp": "$(date -Iseconds)",
  "progress": $4
}
EOF
}

# Usage in provision-customer.sh:
track_state "$DOMAIN" "payment_confirmed" "Payment verified" 0
track_state "$DOMAIN" "terraform_init" "Initializing..." 10
track_state "$DOMAIN" "vpc_creating" "Creating network" 20
track_state "$DOMAIN" "ec2_launching" "Launching server" 40
track_state "$DOMAIN" "panel_installing" "Installing panel" 60
track_state "$DOMAIN" "dns_configuring" "Configuring DNS" 85
track_state "$DOMAIN" "completed" "Server ready!" 100

# API endpoint (simple):
# scripts/api/get-status.sh
cat "/var/neo/states/${DOMAIN}.json"
