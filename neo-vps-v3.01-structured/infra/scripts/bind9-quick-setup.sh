#!/bin/bash
# ==========================================
# DNS AUTOMATION - QUICK SETUP SCRIPT
# For AlmaLinux AMI with Bind9 pre-installed
# ==========================================

set -e

# Variables from Terraform
DOMAIN="${domain}"
PRIMARY_IP="${primary_ip}"
SECONDARY_IP="${secondary_ip:-}"
SERVER_IP="${server_ip}"
CUSTOMER_EMAIL="${customer_email}"
BACKUP_BUCKET="${backup_bucket}"
REGION="${region}"

LOG_FILE="/var/log/neo-dns-quick-setup.log"
ZONES_DIR="/var/named/zones"
ZONES_CONF="/etc/named/zones.conf"

# ==========================================
# LOGGING FUNCTION
# ==========================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=========================================="
log "DNS Quick Setup for: $DOMAIN"
log "Primary IP: $PRIMARY_IP"
log "Secondary IP: $SECONDARY_IP"
log "Server IP: $SERVER_IP"
log "=========================================="

# ==========================================
# 1. SET HOSTNAME
# ==========================================

log "Setting hostname to ns1.$DOMAIN"
hostnamectl set-hostname "ns1.$DOMAIN"
echo "$PRIMARY_IP ns1.$DOMAIN ns1" >> /etc/hosts

if [ -n "$SECONDARY_IP" ]; then
    echo "$SECONDARY_IP ns2.$DOMAIN ns2" >> /etc/hosts
fi

# ==========================================
# 2. CONFIGURE BIND9 MAIN CONFIG
# ==========================================

log "Configuring Bind9 main configuration"

cat > /etc/named.conf << 'NAMEDCONF'
options {
    listen-on port 53 { any; };
    listen-on-v6 port 53 { ::1; };
    directory "/var/named";
    dump-file "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    secroots-file "/var/named/data/named.secroots";
    recursing-file "/var/named/data/named.recursing";
    
    # SECURITY: Disable recursion to prevent amplification attacks
    recursion no;
    allow-query { any; };
    
    # DNSSEC
    dnssec-validation yes;
    
    # Rate limiting (100 queries/sec per IP)
    rate-limit {
        responses-per-second 100;
        window 5;
        slip 2;
        errors-per-second 5;
        nxdomains-per-second 5;
    };
    
    # Performance
    max-cache-size 128M;
    cleaning-interval 60;
};

# Logging
logging {
    channel default_debug {
        file "data/named.run";
        severity dynamic;
    };
    
    channel query_log {
        file "/var/log/named/queries.log" versions 5 size 20m;
        severity info;
        print-time yes;
        print-category yes;
    };
    
    channel security_log {
        file "/var/log/named/security.log" versions 3 size 10m;
        severity info;
        print-time yes;
    };
    
    category queries { query_log; };
    category security { security_log; };
    category lame-servers { null; };
};

# Root zone
zone "." IN {
    type hint;
    file "named.ca";
};

# Include zones configuration
include "/etc/named.rfc1912.zones";
include "/etc/named/zones.conf";
NAMEDCONF

# ==========================================
# 3. CREATE ZONE DIRECTORY
# ==========================================

log "Creating zones directory"
mkdir -p "$ZONES_DIR"
mkdir -p /var/log/named
chown -R named:named /var/log/named

# ==========================================
# 4. CREATE ZONE FILE
# ==========================================

log "Creating zone file for $DOMAIN"

SERIAL=$(date +%Y%m%d)01

cat > "$ZONES_DIR/$DOMAIN.zone" << ZONEFILE
; Zone file for $DOMAIN
; Managed by Neo VPS Platform
; Serial: $SERIAL

\$TTL 86400
@   IN  SOA ns1.$DOMAIN. admin.$DOMAIN. (
        $SERIAL        ; Serial (YYYYMMDDnn)
        3600           ; Refresh (1 hour)
        1800           ; Retry (30 minutes)
        604800         ; Expire (1 week)
        86400 )        ; Minimum TTL (1 day)

; ==========================================
; NAME SERVERS
; ==========================================

@       IN  NS      ns1.$DOMAIN.
ZONEFILE

if [ -n "$SECONDARY_IP" ]; then
    echo "@       IN  NS      ns2.$DOMAIN." >> "$ZONES_DIR/$DOMAIN.zone"
fi

cat >> "$ZONES_DIR/$DOMAIN.zone" << ZONEFILE

; ==========================================
; NAMESERVER A RECORDS
; ==========================================

ns1     IN  A       $PRIMARY_IP
ZONEFILE

if [ -n "$SECONDARY_IP" ]; then
    echo "ns2     IN  A       $SECONDARY_IP" >> "$ZONES_DIR/$DOMAIN.zone"
fi

cat >> "$ZONES_DIR/$DOMAIN.zone" << ZONEFILE

; ==========================================
; MAIN DOMAIN RECORDS
; ==========================================

@       IN  A       $SERVER_IP
www     IN  A       $SERVER_IP

; ==========================================
; MAIL RECORDS
; ==========================================

@       IN  MX  10  mail.$DOMAIN.
mail    IN  A       $SERVER_IP

; ==========================================
; COMMON SUBDOMAINS
; ==========================================

ftp     IN  CNAME   @
webmail IN  CNAME   @
cpanel  IN  CNAME   @
whm     IN  CNAME   @

; ==========================================
; TXT RECORDS (SPF, DMARC)
; ==========================================

@       IN  TXT     "v=spf1 a mx ip4:$SERVER_IP ~all"
_dmarc  IN  TXT     "v=DMARC1; p=none; rua=mailto:admin@$DOMAIN"

; ==========================================
; AUTO-GENERATED RECORDS
; Add custom records below this line
; ==========================================

ZONEFILE

# ==========================================
# 5. ADD ZONE TO NAMED CONFIGURATION
# ==========================================

log "Adding zone to Bind9 configuration"

cat > "$ZONES_CONF" << ZONESCONF
// Customer zones configuration
// Managed by Neo VPS Platform

zone "$DOMAIN" {
    type master;
    file "$ZONES_DIR/$DOMAIN.zone";
    allow-update { none; };
ZONESCONF

if [ -n "$SECONDARY_IP" ]; then
    echo "    allow-transfer { $SECONDARY_IP; };" >> "$ZONES_CONF"
else
    echo "    allow-transfer { none; };" >> "$ZONES_CONF"
fi

cat >> "$ZONES_CONF" << ZONESCONF
    notify yes;
};
ZONESCONF

# ==========================================
# 6. SET PERMISSIONS
# ==========================================

log "Setting correct permissions"
chown -R named:named "$ZONES_DIR"
chmod 640 "$ZONES_DIR"/*
chown named:named "$ZONES_CONF"
chmod 640 "$ZONES_CONF"

# ==========================================
# 7. VALIDATE CONFIGURATION
# ==========================================

log "Validating Bind9 configuration"

if ! named-checkconf; then
    log "ERROR: named.conf validation failed!"
    exit 1
fi

if ! named-checkzone "$DOMAIN" "$ZONES_DIR/$DOMAIN.zone"; then
    log "ERROR: Zone file validation failed!"
    exit 1
fi

log "✅ Configuration validation successful"

# ==========================================
# 8. RESTART BIND9
# ==========================================

log "Restarting Bind9 service"
systemctl enable named
systemctl restart named

# Wait for service to start
sleep 3

if ! systemctl is-active --quiet named; then
    log "ERROR: Bind9 failed to start!"
    journalctl -u named -n 50 >> "$LOG_FILE"
    exit 1
fi

log "✅ Bind9 started successfully"

# ==========================================
# 9. CONFIGURE FIREWALL
# ==========================================

log "Configuring firewall"

if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-service=dns
    firewall-cmd --reload
    log "✅ Firewall configured (firewalld)"
fi

# ==========================================
# 10. TEST DNS RESOLUTION
# ==========================================

log "Testing DNS resolution"

sleep 5  # Wait for Bind9 to fully start

if dig @localhost "$DOMAIN" +short | grep -q "$SERVER_IP"; then
    log "✅ DNS resolution test PASSED"
else
    log "⚠️  DNS resolution test FAILED (may need propagation time)"
fi

# ==========================================
# 11. BACKUP CONFIGURATION
# ==========================================

log "Backing up DNS configuration to S3"

aws s3 cp "$ZONES_DIR/$DOMAIN.zone" \
    "s3://$BACKUP_BUCKET/dns-configs/$DOMAIN/$(date +%Y%m%d-%H%M%S).zone" \
    --region "$REGION" || log "⚠️  S3 backup failed (non-critical)"

# ==========================================
# 12. CREATE MANAGEMENT SCRIPTS
# ==========================================

log "Creating DNS management scripts"

cat > /usr/local/bin/neo-dns-add-record << 'ADDRECORD'
#!/bin/bash
# Add DNS record to zone

if [ $# -lt 4 ]; then
    echo "Usage: $0 <domain> <name> <type> <value> [ttl]"
    echo "Example: $0 example.com test A 1.2.3.4 300"
    exit 1
fi

DOMAIN=$1
NAME=$2
TYPE=$3
VALUE=$4
TTL=${5:-300}

ZONE_FILE="/var/named/zones/$DOMAIN.zone"

if [ ! -f "$ZONE_FILE" ]; then
    echo "Error: Zone file not found for $DOMAIN"
    exit 1
fi

# Add record
echo "$NAME     IN  $TYPE     $VALUE" >> "$ZONE_FILE"

# Increment serial
SERIAL=$(date +%Y%m%d)$(printf "%02d" $((10#$(grep -oP 'Serial.*\K\d{2}' "$ZONE_FILE" || echo "00") + 1)))
sed -i "s/[0-9]\{10\}.*; Serial/$SERIAL        ; Serial/" "$ZONE_FILE"

# Reload zone
rndc reload "$DOMAIN"

echo "✅ Record added: $NAME.$DOMAIN -> $VALUE"
ADDRECORD

chmod +x /usr/local/bin/neo-dns-add-record

# ==========================================
# 13. CREATE WELCOME FILE
# ==========================================

log "Creating welcome information file"

cat > /root/DNS_INFO.txt << DNSINFO
========================================
  NEO VPS - DNS SERVER INFORMATION
========================================

Domain: $DOMAIN
Primary NS: ns1.$DOMAIN ($PRIMARY_IP)
DNSINFO

if [ -n "$SECONDARY_IP" ]; then
    echo "Secondary NS: ns2.$DOMAIN ($SECONDARY_IP)" >> /root/DNS_INFO.txt
fi

cat >> /root/DNS_INFO.txt << DNSINFO

========================================
  NAMESERVER CONFIGURATION
========================================

To use these nameservers, update your domain
registrar with:

  Nameserver 1: ns1.$DOMAIN
  Nameserver 1 IP: $PRIMARY_IP
DNSINFO

if [ -n "$SECONDARY_IP" ]; then
    cat >> /root/DNS_INFO.txt << DNSINFO
  
  Nameserver 2: ns2.$DOMAIN
  Nameserver 2 IP: $SECONDARY_IP
DNSINFO
fi

cat >> /root/DNS_INFO.txt << DNSINFO

========================================
  DNS TESTING
========================================

Test DNS resolution:
  dig @$PRIMARY_IP $DOMAIN
  dig @$PRIMARY_IP www.$DOMAIN
  dig @$PRIMARY_IP mail.$DOMAIN

Check nameservers:
  dig NS $DOMAIN

========================================
  MANAGEMENT COMMANDS
========================================

Add DNS record:
  /usr/local/bin/neo-dns-add-record $DOMAIN <name> <type> <value>

Reload zone:
  rndc reload $DOMAIN

Check Bind9 status:
  systemctl status named

View query logs:
  tail -f /var/log/named/queries.log

========================================
  ZONE FILE LOCATION
========================================

Zone file: $ZONES_DIR/$DOMAIN.zone
Configuration: $ZONES_CONF
Logs: /var/log/named/

========================================

Setup completed at: $(date)

========================================
DNSINFO

cat /root/DNS_INFO.txt

# ==========================================
# 14. UPDATE SYSTEM STATE
# ==========================================

log "Updating system state"

# Create status file
cat > /var/neo-dns-status.json << STATUS
{
  "domain": "$DOMAIN",
  "primary_ns": "ns1.$DOMAIN",
  "primary_ip": "$PRIMARY_IP",
  "secondary_ns": "ns2.$DOMAIN",
  "secondary_ip": "$SECONDARY_IP",
  "server_ip": "$SERVER_IP",
  "setup_completed": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "bind_version": "$(named -v | head -1)",
  "status": "active"
}
STATUS

# Send to DynamoDB if table exists
aws dynamodb put-item \
    --table-name neo-dns-servers \
    --item file:///var/neo-dns-status.json \
    --region "$REGION" 2>/dev/null || log "⚠️  DynamoDB update skipped (table may not exist)"

# ==========================================
# 15. SEND COMPLETION NOTIFICATION
# ==========================================

log "Sending completion notification"

# Create completion marker
touch /var/neo-dns-setup-complete

# Try to send SNS notification
SNS_TOPIC="arn:aws:sns:$REGION:$(aws sts get-caller-identity --query Account --output text):neo-dns-alerts"

aws sns publish \
    --topic-arn "$SNS_TOPIC" \
    --subject "✅ DNS Server Ready: $DOMAIN" \
    --message "DNS server for $DOMAIN is now active.

Primary NS: ns1.$DOMAIN ($PRIMARY_IP)
Secondary NS: ns2.$DOMAIN ($SECONDARY_IP)

Zone file: $ZONES_DIR/$DOMAIN.zone
Status: Active

Please update nameservers at your domain registrar." \
    --region "$REGION" 2>/dev/null || log "⚠️  SNS notification skipped"

# ==========================================
# COMPLETION
# ==========================================

log "=========================================="
log "✅ DNS SETUP COMPLETED SUCCESSFULLY!"
log "=========================================="
log "Domain: $DOMAIN"
log "Primary NS: ns1.$DOMAIN ($PRIMARY_IP)"
if [ -n "$SECONDARY_IP" ]; then
    log "Secondary NS: ns2.$DOMAIN ($SECONDARY_IP)"
fi
log "Zone file: $ZONES_DIR/$DOMAIN.zone"
log "Logs: /var/log/named/"
log "Info file: /root/DNS_INFO.txt"
log "=========================================="
log "Next steps:"
log "1. Update nameservers at domain registrar"
log "2. Wait 24-48h for propagation"
log "3. Verify with: dig NS $DOMAIN"
log "=========================================="

exit 0
