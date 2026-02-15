#!/bin/bash
# ================================================================
# CONTINUOUS HEALTH MONITORING
# ================================================================
# Runs periodic health checks on active servers
# To be run via cron every 5 minutes
# ================================================================

set -euo pipefail

# Configuration
CHECK_INTERVAL=300  # 5 minutes
LOG_FILE="/var/log/neo-health-monitor.log"
API_ENDPOINT="${API_ENDPOINT:-}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE"
}

# Get list of active servers from API or file
get_active_servers() {
    if [[ -n "$API_ENDPOINT" ]]; then
        # Get from API
        curl -s "$API_ENDPOINT/servers?status=active" | jq -r '.[] | "\(.domain) \(.elastic_ip) \(.panel)"'
    else
        # Get from local file (fallback)
        if [[ -f /etc/neo/active-servers.txt ]]; then
            cat /etc/neo/active-servers.txt
        else
            echo ""
        fi
    fi
}

# Check single server
check_server() {
    local domain="$1"
    local ip="$2"
    local panel="$3"
    
    log "Checking $domain ($ip)..."
    
    # Ping check
    if ! ping -c 2 -W 3 "$ip" &>/dev/null; then
        log_error "$domain: Server not responding to ping"
        send_alert "$domain" "Server not responding to ping"
        return 1
    fi
    
    # Panel-specific check
    case "$panel" in
        cyberpanel)
            if ! timeout 5 nc -zv "$ip" 8090 &>/dev/null; then
                log_error "$domain: CyberPanel not responding"
                send_alert "$domain" "CyberPanel not responding"
                return 1
            fi
            ;;
        cpanel)
            if ! timeout 5 nc -zv "$ip" 2087 &>/dev/null; then
                log_error "$domain: cPanel/WHM not responding"
                send_alert "$domain" "cPanel/WHM not responding"
                return 1
            fi
            ;;
        *)
            # Check HTTP for others
            if ! timeout 5 nc -zv "$ip" 80 &>/dev/null; then
                log_error "$domain: Web server not responding"
                send_alert "$domain" "Web server not responding"
                return 1
            fi
            ;;
    esac
    
    log_success "$domain: Health check passed"
    return 0
}

# Send alert
send_alert() {
    local domain="$1"
    local message="$2"
    
    # Send to API
    if [[ -n "$API_ENDPOINT" ]]; then
        curl -X POST "$API_ENDPOINT/alerts" \
            -H "Content-Type: application/json" \
            -d "{\"domain\": \"$domain\", \"message\": \"$message\", \"severity\": \"error\"}" \
            2>/dev/null || true
    fi
    
    # Send SNS (if configured)
    if [[ -n "${SNS_TOPIC_ARN:-}" ]]; then
        aws sns publish \
            --topic-arn "$SNS_TOPIC_ARN" \
            --subject "NEO VPS Alert: $domain" \
            --message "$message" \
            2>/dev/null || true
    fi
}

# Main
main() {
    log "=== Starting health monitoring ==="
    
    local total=0
    local failed=0
    
    while IFS= read -r line; do
        if [[ -z "$line" ]]; then
            continue
        fi
        
        read -r domain ip panel <<< "$line"
        
        ((total++))
        
        if ! check_server "$domain" "$ip" "$panel"; then
            ((failed++))
        fi
        
    done < <(get_active_servers)
    
    log "=== Health monitoring complete: $total servers checked, $failed failures ==="
}

main
