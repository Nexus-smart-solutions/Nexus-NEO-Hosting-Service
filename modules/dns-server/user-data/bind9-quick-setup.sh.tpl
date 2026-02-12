#!/bin/bash
set -e

DOMAIN="${domain}"
PRIMARY_IP="${primary_ip}"
SECONDARY_IP="${secondary_ip}"
LOG="/var/log/neo-dns-setup.log"

log() { echo "[$(date)] $1" | tee -a $LOG; }

log "Starting DNS configuration for $DOMAIN"

# 1. Update hostname
hostnamectl set-hostname ns1.$DOMAIN
echo "$PRIMARY_IP ns1.$DOMAIN ns1" >> /etc/hosts

# 2. Configure Bind9 zones
cat > /etc/named.conf << 'EOF'
options {
    listen-on port 53 { any; };
    directory "/var/named";
    dump-file "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    
    recursion no;  # Security: disable recursion
    allow-query { any; };
    dnssec-validation yes;
    
    rate-limit {
        responses-per-second 10;
        window 5;
    };
};

logging {
    channel default_debug {
        file "data/named.run";
        severity dynamic;
    };
    channel query_log {
        file "/var/log/named/queries.log" versions 3 size 10m;
        severity info;
        print-time yes;
    };
    category queries { query_log; };
};

zone "." IN {
    type hint;
    file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named/zones.conf";
EOF

# 3. Create zone file for customer domain
mkdir -p /var/named/zones
cat > /var/named/zones/$DOMAIN.zone << EOF
\$TTL 86400
@   IN  SOA ns1.$DOMAIN. admin.$DOMAIN. (
        $(date +%Y%m%d)01  ; Serial
        3600               ; Refresh
        1800               ; Retry
        604800             ; Expire
        86400 )            ; Minimum TTL

; Name servers
@       IN  NS      ns1.$DOMAIN.
@       IN  NS      ns2.$DOMAIN.

; A records for name servers
ns1     IN  A       $PRIMARY_IP
ns2     IN  A       $SECONDARY_IP

; Main domain
@       IN  A       ${server_ip}
www     IN  A       ${server_ip}

; Mail
@       IN  MX  10  mail.$DOMAIN.
mail    IN  A       ${server_ip}

; Default records
ftp     IN  CNAME   @
EOF

# 4. Add zone to named config
cat > /etc/named/zones.conf << EOF
zone "$DOMAIN" {
    type master;
    file "/var/named/zones/$DOMAIN.zone";
    allow-transfer { $SECONDARY_IP; };
};
EOF

# 5. Set permissions
chown -R named:named /var/named/zones
chmod 640 /var/named/zones/*

# 6. Validate and restart
named-checkconf
named-checkzone $DOMAIN /var/named/zones/$DOMAIN.zone

systemctl enable named
systemctl restart named

# 7. Configure firewall
firewall-cmd --permanent --add-service=dns
firewall-cmd --reload

# 8. Save configuration to S3
aws s3 cp /var/named/zones/$DOMAIN.zone s3://${backup_bucket}/dns-configs/$DOMAIN.zone

log "DNS server configured successfully!"
log "Test with: dig @$PRIMARY_IP $DOMAIN"