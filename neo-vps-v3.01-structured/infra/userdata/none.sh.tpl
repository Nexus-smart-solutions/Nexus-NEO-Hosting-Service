#!/bin/bash
# ==========================================
# Base Server Setup (No Control Panel)
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
log "Starting base server setup for: $DOMAIN"
log "=========================================="

# ==========================================
# System Update
# ==========================================

log "Updating system packages..."
if command -v dnf &> /dev/null; then
    dnf update -y >> "$LOG_FILE" 2>&1
else
    yum update -y >> "$LOG_FILE" 2>&1
fi

# ==========================================
# Install Essential Packages
# ==========================================

log "Installing essential packages..."
if command -v dnf &> /dev/null; then
    dnf install -y \
        vim \
        nano \
        htop \
        curl \
        wget \
        git \
        net-tools \
        bind-utils \
        telnet \
        nc \
        zip \
        unzip \
        tar \
        rsync \
        screen \
        tmux \
        fail2ban \
        firewalld >> "$LOG_FILE" 2>&1
else
    yum install -y \
        vim \
        nano \
        htop \
        curl \
        wget \
        git \
        net-tools \
        bind-utils \
        telnet \
        nc \
        zip \
        unzip \
        tar \
        rsync \
        screen \
        tmux \
        fail2ban \
        firewalld >> "$LOG_FILE" 2>&1
fi

# ==========================================
# Configure Hostname
# ==========================================

log "Setting hostname to: $DOMAIN"
hostnamectl set-hostname $DOMAIN
echo "127.0.0.1 $DOMAIN" >> /etc/hosts

# ==========================================
# Configure Firewall
# ==========================================

log "Configuring firewall..."
systemctl start firewalld
systemctl enable firewalld

# Allow SSH
firewall-cmd --permanent --add-service=ssh >> "$LOG_FILE" 2>&1
# Allow HTTP
firewall-cmd --permanent --add-service=http >> "$LOG_FILE" 2>&1
# Allow HTTPS
firewall-cmd --permanent --add-service=https >> "$LOG_FILE" 2>&1

firewall-cmd --reload >> "$LOG_FILE" 2>&1

log "Firewall configured - SSH, HTTP, and HTTPS enabled"

# ==========================================
# Configure Fail2Ban
# ==========================================

log "Configuring Fail2Ban..."
systemctl start fail2ban
systemctl enable fail2ban

cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = /var/log/secure
EOF

systemctl restart fail2ban
log "Fail2Ban configured and started"

# ==========================================
# Set Timezone
# ==========================================

log "Setting timezone to UTC..."
timedatectl set-timezone UTC

# ==========================================
# Configure Automatic Security Updates
# ==========================================

log "Enabling automatic security updates..."
if command -v dnf &> /dev/null; then
    dnf install -y dnf-automatic >> "$LOG_FILE" 2>&1
    systemctl enable --now dnf-automatic.timer
else
    yum install -y yum-cron >> "$LOG_FILE" 2>&1
    systemctl enable --now yum-cron
fi

# ==========================================
# Create Swap File (if not exists)
# ==========================================

if [ ! -f /swapfile ]; then
    log "Creating 2GB swap file..."
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile >> "$LOG_FILE" 2>&1
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    log "Swap file created and enabled"
fi

# ==========================================
# Optimize System Performance
# ==========================================

log "Applying system optimizations..."

# Increase file limits
cat >> /etc/security/limits.conf << EOF
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
EOF

# Optimize sysctl
cat >> /etc/sysctl.conf << EOF
# Network optimizations
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_window_scaling = 1

# Security
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
EOF

sysctl -p >> "$LOG_FILE" 2>&1

# ==========================================
# Get Server IP
# ==========================================

SERVER_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "Unable to detect")
log "Server public IP: $SERVER_IP"

# ==========================================
# Create Welcome Message
# ==========================================

cat > /root/WELCOME.txt << EOF
========================================
  NEO VPS - Clean Server Setup
========================================

Domain: $DOMAIN
Server IP: $SERVER_IP
OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
Kernel: $(uname -r)

========================================
  Server Access
========================================

SSH: ssh root@$SERVER_IP

========================================
  Installed Software
========================================

✓ System updated to latest packages
✓ Essential tools (vim, htop, curl, wget, git)
✓ Firewall (firewalld) - SSH, HTTP, HTTPS enabled
✓ Fail2Ban - SSH brute force protection
✓ Automatic security updates enabled
✓ 2GB Swap file created
✓ System optimizations applied

========================================
  Security Features
========================================

- Firewall: Active and enabled
- Fail2Ban: Protecting SSH (5 attempts, 1hr ban)
- Automatic security updates: Enabled
- SELinux: $(getenforce 2>/dev/null || echo "Not available")

========================================
  Next Steps
========================================

This is a clean server ready for your custom setup!

Suggested next steps:
1. Install web server (Nginx/Apache)
2. Install database (MySQL/PostgreSQL)
3. Install PHP/Python/Node.js
4. Configure SSL certificates
5. Deploy your application

========================================
  Useful Commands
========================================

- Update system: dnf update -y
- Check firewall: firewall-cmd --list-all
- Fail2Ban status: fail2ban-client status sshd
- Check disk space: df -h
- Check memory: free -h
- View logs: journalctl -xe

========================================
  Support Resources
========================================

Documentation: /var/log/neo-vps-setup.log
System logs: /var/log/messages

========================================

Setup completed at: $(date)

========================================
EOF

log "=========================================="
log "Base server setup completed successfully!"
log "Domain: $DOMAIN"
log "Server IP: $SERVER_IP"
log "=========================================="

# Display welcome message
cat /root/WELCOME.txt

# Create MOTD
cp /root/WELCOME.txt /etc/motd

# Send completion marker
echo "BASE_SETUP_COMPLETE" > /var/log/installation_complete.flag

log "Setup script finished"
