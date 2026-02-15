#!/bin/bash
# ================================================================
# BIND9 SECONDARY DNS SETUP
# ================================================================
# Configures server as secondary DNS (slave)
# ================================================================

set -e

PRIMARY_DNS_IP="${primary_dns_ip}"
DOMAIN_SUFFIX="${domain_suffix}"

# Update system
dnf update -y

# Install Bind9
dnf install -y bind bind-utils

# Configure as secondary
cat > /etc/named.conf << 'EOF'
options {
    listen-on port 53 { any; };
    listen-on-v6 port 53 { any; };
    directory "/var/named";
    dump-file "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    allow-query { any; };
    recursion no;
    dnssec-validation no;
    managed-keys-directory "/var/named/dynamic";
};

logging {
    channel default_debug {
        file "data/named.run";
        severity dynamic;
    };
};

zone "." IN {
    type hint;
    file "named.ca";
};

include "/etc/named/zones.conf";
EOF

# Create zones config directory
mkdir -p /etc/named
touch /etc/named/zones.conf

# Enable and start
systemctl enable named
systemctl start named

# Firewall
firewall-cmd --permanent --add-service=dns
firewall-cmd --reload

# Install health check script
cat > /usr/local/bin/dns-health.sh << 'HEALTH'
#!/bin/bash
if systemctl is-active --quiet named; then
    exit 0
else
    systemctl restart named
    exit 1
fi
HEALTH

chmod +x /usr/local/bin/dns-health.sh

# Cron for health check
echo "*/5 * * * * /usr/local/bin/dns-health.sh" | crontab -

echo "Secondary DNS setup complete"
