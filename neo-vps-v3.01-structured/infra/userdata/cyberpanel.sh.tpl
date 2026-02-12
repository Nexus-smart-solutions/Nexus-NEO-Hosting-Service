#!/bin/bash
# ==========================================
# CyberPanel Installation Script
# For Neo VPS Provisioning System
# ==========================================

set -e  # Exit on any error

# Variables from Terraform
DOMAIN="${domain}"
LOG_FILE="/var/log/neo-vps-setup.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=========================================="
log "Starting CyberPanel installation for: $DOMAIN"
log "=========================================="

# ==========================================
# System Update
# ==========================================

log "Updating system packages..."
dnf update -y >> "$LOG_FILE" 2>&1

# ==========================================
# Fix MariaDB Dependency Issue
# ==========================================

log "Installing MariaDB development packages..."
dnf install -y MariaDB-devel MariaDB-shared mariadb-connector-c-devel >> "$LOG_FILE" 2>&1

# ==========================================
# Download and Fix CyberPanel Installer
# ==========================================

log "Downloading CyberPanel installer..."
wget -O /tmp/cyberpanel_install.sh https://cyberpanel.net/install.sh >> "$LOG_FILE" 2>&1

log "Fixing MariaDB dependency in installer..."
sed -i 's/mariadb-devel/MariaDB-devel/g' /tmp/cyberpanel_install.sh

# ==========================================
# Auto-Install CyberPanel
# ==========================================

log "Starting CyberPanel installation (this may take 15-20 minutes)..."

# Installation answers:
# 1 = Install CyberPanel
# 1 = Install with OpenLiteSpeed
# Y = Full installation (PowerDNS, Postfix, Pure-FTPd)
# N = No Remote MySQL (use local)
# (empty) = Use latest version
# r = Generate random admin password
# Y = Install Memcached
# Y = Install Redis
# Yes = Setup Watchdog

echo -e "1\n1\nY\nN\n\nr\nY\nY\nYes" | bash /tmp/cyberpanel_install.sh >> "$LOG_FILE" 2>&1

# ==========================================
# Wait for CyberPanel to finish setup
# ==========================================

log "Waiting for CyberPanel services to start..."
sleep 60

# ==========================================
# Get Admin Password
# ==========================================

log "Retrieving admin password..."
if [ -f /root/.litespeed_password ]; then
    ADMIN_PASSWORD=$(cat /root/.litespeed_password)
    echo "$ADMIN_PASSWORD" > /root/.cyberpanel_password
    log "Admin password saved to /root/.cyberpanel_password"
else
    log "Warning: Admin password file not found!"
fi

# ==========================================
# Configure Firewall
# ==========================================

log "Configuring firewall..."
if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=8090/tcp >> "$LOG_FILE" 2>&1 || true
    firewall-cmd --permanent --add-port=80/tcp >> "$LOG_FILE" 2>&1 || true
    firewall-cmd --permanent --add-port=443/tcp >> "$LOG_FILE" 2>&1 || true
    firewall-cmd --permanent --add-port=21/tcp >> "$LOG_FILE" 2>&1 || true
    firewall-cmd --permanent --add-port=40110-40210/tcp >> "$LOG_FILE" 2>&1 || true
    firewall-cmd --reload >> "$LOG_FILE" 2>&1 || true
    log "Firewall configured successfully"
fi

# ==========================================
# Get Server IP
# ==========================================

SERVER_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
log "Server public IP: $SERVER_IP"

# ==========================================
# Create Welcome Message
# ==========================================

cat > /root/WELCOME.txt << EOF
========================================
  NEO VPS - CyberPanel Installation
========================================

Domain: $DOMAIN
Server IP: $SERVER_IP

========================================
  CyberPanel Access
========================================

URL: https://$SERVER_IP:8090
Username: admin
Password: $(cat /root/.cyberpanel_password 2>/dev/null || echo "Check /root/.litespeed_password")

========================================
  SSH Access
========================================

ssh root@$SERVER_IP

========================================
  Important Files
========================================

- Admin Password: /root/.cyberpanel_password
- Installation Log: /var/log/neo-vps-setup.log
- CyberPanel Logs: /var/log/cyberpanel/

========================================
  Next Steps
========================================

1. Login to CyberPanel: https://$SERVER_IP:8090
2. Create your first website
3. Configure DNS records to point to: $SERVER_IP
4. Install SSL certificate (Let's Encrypt)

========================================
  Useful Commands
========================================

- Restart CyberPanel: systemctl restart lscpd
- Check status: systemctl status lscpd
- View logs: tail -f /var/log/cyberpanel/access.log

========================================

Installation completed at: $(date)

========================================
EOF

log "=========================================="
log "CyberPanel installation completed successfully!"
log "Domain: $DOMAIN"
log "Server IP: $SERVER_IP"
log "Admin Panel: https://$SERVER_IP:8090"
log "Username: admin"
log "Password: Check /root/.cyberpanel_password"
log "=========================================="

# Display welcome message
cat /root/WELCOME.txt

# Send completion marker
echo "CYBERPANEL_INSTALLATION_COMPLETE" > /var/log/installation_complete.flag

log "Installation script finished"
