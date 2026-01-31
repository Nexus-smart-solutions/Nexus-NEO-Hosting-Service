#!/bin/bash
# ===================================
# CPANEL SERVER PREPARATION SCRIPT
# ===================================

set -e

# Logging
exec > >(tee /var/log/userdata.log)
exec 2>&1

echo "Starting cPanel server preparation..."
echo "Hostname will be: ${hostname}"

# Set hostname
hostnamectl set-hostname ${hostname}

# Disable SELinux (cPanel requirement)
setenforce 0 2>/dev/null || true
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# Update system
yum update -y

# Install required packages
yum install -y wget curl vim net-tools perl screen

# Format and mount data volume
if [ -b /dev/nvme1n1 ]; then
    if ! blkid /dev/nvme1n1; then
        mkfs.ext4 /dev/nvme1n1
    fi
    
    mkdir -p /home
    
    if ! grep -q "/dev/nvme1n1" /etc/fstab; then
        echo "/dev/nvme1n1 /home ext4 defaults,nofail 0 2" >> /etc/fstab
    fi
    
    mount -a
    echo "Data volume mounted at /home"
fi

# Disable NetworkManager (cPanel requirement)
systemctl stop NetworkManager 2>/dev/null || true
systemctl disable NetworkManager 2>/dev/null || true

# Install CloudWatch agent
cd /tmp
wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/centos/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm || true

# Create cPanel installation helper script
cat > /root/install-cpanel.sh << 'CPANELINSTALL'
#!/bin/bash
echo "cPanel Installation Script"
echo "Current hostname: $(hostname)"
echo "Checking DNS..."
host $(hostname)
echo ""
read -p "Continue with cPanel installation? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Installation cancelled."
    exit 0
fi
cd /home
curl -o latest -L https://securedownloads.cpanel.net/latest
sh latest
CPANELINSTALL

chmod +x /root/install-cpanel.sh

echo "Server preparation completed!"
echo "To install cPanel, run: /root/install-cpanel.sh"
