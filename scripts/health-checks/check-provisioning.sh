#!/bin/bash
# ================================================================
# PROVISIONING HEALTH CHECK
# ================================================================
# Validates successful server provisioning
# Checks: Panel installation, services, connectivity
# Exit codes: 0 = success, 1 = failure
# ================================================================

set -euo pipefail

# Configuration
DOMAIN="${1:-}"
PANEL="${2:-none}"
SERVER_IP="${3:-}"
TIMEOUT=900  # 15 minutes
CHECK_INTERVAL=30  # 30 seconds

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

# Validate arguments
if [[ -z "$DOMAIN" ]] || [[ -z "$SERVER_IP" ]]; then
    log_error "Usage: $0 <domain> <panel> <server_ip>"
    exit 1
fi

log "Starting health check for $DOMAIN ($PANEL)"
log "Server IP: $SERVER_IP"

# ================================================================
# BASIC CONNECTIVITY
# ================================================================

check_connectivity() {
    log "Checking server connectivity..."
    
    if ping -c 3 -W 5 "$SERVER_IP" &>/dev/null; then
        log_success "Server is reachable"
        return 0
    else
        log_error "Server is not reachable"
        return 1
    fi
}

# ================================================================
# SSH CHECK
# ================================================================

check_ssh() {
    log "Checking SSH connectivity..."
    
    if timeout 10 nc -zv "$SERVER_IP" 22 &>/dev/null; then
        log_success "SSH port (22) is open"
        return 0
    else
        log_error "SSH port (22) is not accessible"
        return 1
    fi
}

# ================================================================
# HTTP/HTTPS CHECK
# ================================================================

check_web() {
    log "Checking web server..."
    
    # Check HTTP (port 80)
    if timeout 10 nc -zv "$SERVER_IP" 80 &>/dev/null; then
        log_success "HTTP port (80) is open"
    else
        log_warning "HTTP port (80) is not open"
    fi
    
    # Check HTTPS (port 443)
    if timeout 10 nc -zv "$SERVER_IP" 443 &>/dev/null; then
        log_success "HTTPS port (443) is open"
    else
        log_warning "HTTPS port (443) is not open (may be expected)"
    fi
    
    return 0
}

# ================================================================
# PANEL-SPECIFIC CHECKS
# ================================================================

check_cyberpanel() {
    log "Checking CyberPanel installation..."
    
    # CyberPanel runs on port 8090
    local max_attempts=$((TIMEOUT / CHECK_INTERVAL))
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if timeout 10 nc -zv "$SERVER_IP" 8090 &>/dev/null; then
            log_success "CyberPanel port (8090) is accessible"
            
            # Try to get response
            if curl -k -s -o /dev/null -w "%{http_code}" "https://$SERVER_IP:8090" | grep -q "200\|302\|301"; then
                log_success "CyberPanel is responding"
                return 0
            fi
        fi
        
        attempt=$((attempt + 1))
        log "Waiting for CyberPanel... ($attempt/$max_attempts)"
        sleep $CHECK_INTERVAL
    done
    
    log_error "CyberPanel failed to start within timeout"
    return 1
}

check_cpanel() {
    log "Checking cPanel/WHM installation..."
    
    # WHM runs on port 2087, cPanel on 2083
    local max_attempts=$((TIMEOUT / CHECK_INTERVAL))
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if timeout 10 nc -zv "$SERVER_IP" 2087 &>/dev/null; then
            log_success "WHM port (2087) is accessible"
            
            # Try to get response
            if curl -k -s -o /dev/null -w "%{http_code}" "https://$SERVER_IP:2087" | grep -q "200\|302\|301"; then
                log_success "cPanel/WHM is responding"
                return 0
            fi
        fi
        
        attempt=$((attempt + 1))
        log "Waiting for cPanel/WHM... ($attempt/$max_attempts)"
        sleep $CHECK_INTERVAL
    done
    
    log_error "cPanel/WHM failed to start within timeout"
    return 1
}

check_directadmin() {
    log "Checking DirectAdmin installation..."
    
    # DirectAdmin runs on port 2222
    local max_attempts=$((TIMEOUT / CHECK_INTERVAL))
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if timeout 10 nc -zv "$SERVER_IP" 2222 &>/dev/null; then
            log_success "DirectAdmin port (2222) is accessible"
            
            # Try to get response
            if curl -k -s -o /dev/null -w "%{http_code}" "https://$SERVER_IP:2222" | grep -q "200\|302\|301"; then
                log_success "DirectAdmin is responding"
                return 0
            fi
        fi
        
        attempt=$((attempt + 1))
        log "Waiting for DirectAdmin... ($attempt/$max_attempts)"
        sleep $CHECK_INTERVAL
    done
    
    log_error "DirectAdmin failed to start within timeout"
    return 1
}

# ================================================================
# SYSTEM HEALTH
# ================================================================

check_system_health() {
    log "Checking system health (via SSH if possible)..."
    
    # This would require SSH key access
    # For now, just basic checks
    
    # Check if system is responding to HTTP
    if curl -s -o /dev/null -w "%{http_code}" "http://$SERVER_IP" | grep -q "200\|302\|301\|403\|404"; then
        log_success "Web server is responding"
        return 0
    else
        log_warning "Web server not responding yet"
        return 1
    fi
}

# ================================================================
# DNS CHECK
# ================================================================

check_dns() {
    log "Checking DNS resolution..."
    
    # Check if domain resolves to correct IP
    if dig +short "$DOMAIN" @8.8.8.8 | grep -q "$SERVER_IP"; then
        log_success "DNS resolves correctly: $DOMAIN → $SERVER_IP"
        return 0
    else
        log_warning "DNS not propagated yet (this is normal)"
        return 0  # Don't fail on DNS propagation
    fi
}

# ================================================================
# MAIN EXECUTION
# ================================================================

main() {
    local failed=0
    
    echo ""
    echo "========================================="
    echo "  NEO VPS - PROVISIONING HEALTH CHECK"
    echo "========================================="
    echo "Domain:    $DOMAIN"
    echo "Panel:     $PANEL"
    echo "Server IP: $SERVER_IP"
    echo "========================================="
    echo ""
    
    # Basic checks
    if ! check_connectivity; then
        ((failed++))
    fi
    
    if ! check_ssh; then
        ((failed++))
    fi
    
    check_web  # Non-critical
    
    # Panel-specific check
    case "$PANEL" in
        cyberpanel)
            if ! check_cyberpanel; then
                ((failed++))
            fi
            ;;
        cpanel)
            if ! check_cpanel; then
                ((failed++))
            fi
            ;;
        directadmin)
            if ! check_directadmin; then
                ((failed++))
            fi
            ;;
        none)
            log "No panel to check (clean server)"
            if ! check_system_health; then
                log_warning "System health check inconclusive"
            fi
            ;;
        *)
            log_warning "Unknown panel type: $PANEL"
            ;;
    esac
    
    # DNS check (informational)
    check_dns
    
    echo ""
    echo "========================================="
    
    if [[ $failed -eq 0 ]]; then
        log_success "All health checks passed!"
        log "Server is ready for use"
        echo "========================================="
        exit 0
    else
        log_error "Health check failed ($failed failures)"
        echo "========================================="
        exit 1
    fi
}

main
