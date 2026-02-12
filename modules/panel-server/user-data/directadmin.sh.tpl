#!/bin/bash
# ==========================================
# DirectAdmin Installation Script
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
log "Starting DirectAdmin installation for: $DOMAIN"
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
yum install -y wget gcc gcc-c++ flex bison make bind bind-libs bind-utils openssl openssl-devel perl quota libaio libcom_err-devel libcurl-devel gd zlib-devel zip unzip libcap-devel cronie bzip2 cyrus-sasl-devel perl-ExtUtils-Embed autoconf automake libtool which patch mailx bzip2-devel lsof glibc-headers kernel-devel expat-devel db4-devel >> "$LOG_FILE" 2>&1

# ==========================================
# Set Hostname
# ==========================================

log "Setting hostname..."
hostnamectl set-hostname $DOMAIN
echo "127.0.0.1 $DOMAIN" >> /etc/hosts

# ==========================================
# Download and Install DirectAdmin
# ==========================================

log "Creating DirectAdmin installation directory..."
mkdir -p /root/directadmin
cd /root/directadmin

log "NOTE: DirectAdmin requires a license!"
log "This script will install DirectAdmin, but you need to provide a license key."
log "Get a trial license at: https://www.directadmin.com/trial.php"

# Generate random admin password
ADMIN_PASSWORD=$(openssl rand -base64 16)
echo "$ADMIN_PASSWORD" > /root/.directadmin_password
chmod 600 /root/.directadmin_password

log "Admin password saved to /root/.directadmin_password"

# Download installer
log "Downloading DirectAdmin installer..."
wget -O setup.sh https://www.directadmin.com/setup.sh >> "$LOG_FILE" 2>&1
chmod 755 setup.sh

# Get server IP
SERVER_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

log "=========================================="
log "DirectAdmin installer downloaded."
log "=========================================="
log "IMPORTANT: You need a DirectAdmin license to continue!"
log "Get one at: https://www.directadmin.com/trial.php"
log "=========================================="

# Create installation guide
cat > /root/DIRECTADMIN_INSTALL_GUIDE.txt << EOF
========================================
  DirectAdmin Installation Guide
========================================

Domain: $DOMAIN
Server IP: $SERVER_IP

========================================
  Manual Installation Required
========================================

DirectAdmin requires a license key to install.

Step 1: Get a License
   Visit: https://www.directadmin.com/trial.php
   - Enter your server IP: $SERVER_IP
   - Enter your email
   - Get your Client ID and License ID

Step 2: Run the installer
   cd /root/directadmin
   ./setup.sh

Step 3: Follow the prompts
   - Enter Client ID
   - Enter License ID
   - Enter hostname: $DOMAIN
   - Set admin password: $(cat /root/.directadmin_password)

========================================
  After Installation
========================================

DirectAdmin will be available at:
URL: https://$SERVER_IP:2222
Username: admin
Password: $(cat /root/.directadmin_password)

========================================
  SSH Access
========================================

ssh root@$SERVER_IP

========================================
  Pricing
========================================

DirectAdmin Lite: $5/month
DirectAdmin Standard: $15/month
DirectAdmin Pro: $29/month

Visit: https://www.directadmin.com/pricing.php

========================================

Setup files located at: /root/directadmin/

========================================
EOF

# ==========================================
# Configure Firewall (in preparation)
# ==========================================

log "Configuring firewall..."
if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=2222/tcp >> "$LOG_FILE" 2>&1 || true
    firewall-cmd --permanent --add-port=80/tcp >> "$LOG_FILE" 2>&1 || true
    firewall-cmd --permanent --add-port=443/tcp >> "$LOG_FILE" 2>&1 || true
    firewall-cmd --permanent --add-port=21/tcp >> "$LOG_FILE" 2>&1 || true
    firewall-cmd --permanent --add-port=22/tcp >> "$LOG_FILE" 2>&1 || true
    firewall-cmd --reload >> "$LOG_FILE" 2>&1 || true
    log "Firewall configured successfully"
fi

log "=========================================="
log "DirectAdmin preparation completed!"
log "=========================================="
log "Please read: /root/DIRECTADMIN_INSTALL_GUIDE.txt"
log "=========================================="

# Display guide
cat /root/DIRECTADMIN_INSTALL_GUIDE.txt

# Send completion marker (partial - requires manual step)
echo "DIRECTADMIN_PREPARATION_COMPLETE" > /var/log/installation_complete.flag

log "Preparation script finished - manual installation required"
