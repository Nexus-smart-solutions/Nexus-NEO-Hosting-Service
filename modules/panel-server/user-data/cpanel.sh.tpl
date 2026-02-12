#!/bin/bash
# ==========================================
# cPanel/WHM Installation Script
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
log "Starting cPanel/WHM installation for: $DOMAIN"
log "=========================================="

# ==========================================
# System Update
# ==========================================

log "Updating system packages..."
yum update -y >> "$LOG_FILE" 2>&1

# ==========================================
# Install Required Packages
# ==========================================

log "Installing required packages..."
yum install -y wget curl perl >> "$LOG_FILE" 2>&1

# ==========================================
# Set Hostname
# ==========================================

log "Setting hostname..."
hostnamectl set-hostname $DOMAIN
echo "127.0.0.1 $DOMAIN" >> /etc/hosts

# ==========================================
# Download and Install cPanel
# ==========================================

log "Downloading cPanel installer..."
cd /home
wget -N https://securedownloads.cpanel.net/latest >> "$LOG_FILE" 2>&1

log "Starting cPanel installation (this may take 60-90 minutes)..."
log "WARNING: This is a LONG process, please be patient!"

sh latest >> "$LOG_FILE" 2>&1

# ==========================================
# Wait for WHM to finish setup
# ==========================================

log "Waiting for WHM services to start..."
sleep 120

# ==========================================
# Configure Firewall
# ==========================================

log "Configuring firewall..."
if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=2087/tcp >> "$LOG_FILE" 2>&1 || true
    firewall-cmd --permanent --add-port=2083/tcp >> "$LOG_FILE" 2>&1 || true
    firewall-cmd --permanent --add-port=80/tcp >> "$LOG_FILE" 2>&1 || true
    firewall-cmd --permanent --add-port=443/tcp >> "$LOG_FILE" 2>&1 || true
    firewall-cmd --permanent --add-port=21/tcp >> "$LOG_FILE" 2>&1 || true
    firewall-cmd --permanent --add-port=22/tcp >> "$LOG_FILE" 2>&1 || true
    firewall-cmd --reload >> "$LOG_FILE" 2>&1 || true
    log "Firewall configured successfully"
fi

# ==========================================
# Get Server IP & Root Password
# ==========================================

SERVER_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
log "Server public IP: $SERVER_IP"

# Generate random password for WHM
WHM_PASSWORD=$(openssl rand -base64 16)
echo "root:$WHM_PASSWORD" | chpasswd
echo "$WHM_PASSWORD" > /root/.whm_password
chmod 600 /root/.whm_password

log "WHM root password saved to /root/.whm_password"

# ==========================================
# Create Welcome Message
# ==========================================

cat > /root/WELCOME.txt << EOF
========================================
  NEO VPS - cPanel/WHM Installation
========================================

Domain: $DOMAIN
Server IP: $SERVER_IP

========================================
  WHM Access (Root)
========================================

URL: https://$SERVER_IP:2087
Username: root
Password: $(cat /root/.whm_password)

========================================
  cPanel Access (Create account first)
========================================

URL: https://$SERVER_IP:2083
Create accounts via WHM

========================================
  SSH Access
========================================

ssh root@$SERVER_IP
Password: $(cat /root/.whm_password)

========================================
  Important Files
========================================

- WHM Password: /root/.whm_password
- Installation Log: /var/log/neo-vps-setup.log
- cPanel Logs: /usr/local/cpanel/logs/

========================================
  Next Steps
========================================

1. Login to WHM: https://$SERVER_IP:2087
2. Complete initial setup wizard
3. Create your first cPanel account
4. Configure DNS records to point to: $SERVER_IP
5. Install SSL certificates

========================================
  Useful Commands
========================================

- Restart cPanel: /scripts/restartsrv_cpanel
- Check license: /usr/local/cpanel/cpkeyclt
- Update cPanel: /scripts/upcp

========================================
  License Information
========================================

NOTE: cPanel requires a valid license!
You need to add a license key in WHM.

Free Trial: https://cpanel.net/products/trial/
Purchase: https://cpanel.net/pricing/

========================================

Installation completed at: $(date)

========================================
EOF

log "=========================================="
log "cPanel/WHM installation completed successfully!"
log "Domain: $DOMAIN"
log "Server IP: $SERVER_IP"
log "WHM Panel: https://$SERVER_IP:2087"
log "Username: root"
log "Password: Check /root/.whm_password"
log "=========================================="
log "IMPORTANT: You need to add a cPanel license!"
log "=========================================="

# Display welcome message
cat /root/WELCOME.txt

# Send completion marker
echo "CPANEL_INSTALLATION_COMPLETE" > /var/log/installation_complete.flag

log "Installation script finished"
