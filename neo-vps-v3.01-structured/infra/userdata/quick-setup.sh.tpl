#!/bin/bash
set -e

DOMAIN="${domain}"
PANEL="${panel_type}"  # cpanel, cyberpanel, directadmin
LOG="/var/log/neo-panel-setup.log"

log() { echo "[$(date)] $1" | tee -a $LOG; }

log "Starting quick setup for $DOMAIN with $PANEL"

# 1. Set hostname
hostnamectl set-hostname $DOMAIN

# 2. Get instance metadata
INSTANCE_ID=$(ec2-metadata --instance-id | cut -d' ' -f2)
PUBLIC_IP=$(ec2-metadata --public-ipv4 | cut -d' ' -f2)

# 3. Panel-specific config
case $PANEL in
  cpanel)
    # cPanel already installed in AMI, just activate license
    /usr/local/cpanel/cpkeyclt
    
    # Set WHM password
    WHM_PASS=$(openssl rand -base64 16)
    echo "root:$WHM_PASS" | chpasswd
    echo $WHM_PASS > /root/.whm_password
    chmod 600 /root/.whm_password
    
    # Basic security
    /usr/local/cpanel/scripts/configure_firewall_for_cpanel
    
    log "cPanel ready at https://$PUBLIC_IP:2087"
    log "Username: root"
    log "Password: $(cat /root/.whm_password)"
    ;;
    
  cyberpanel)
    # CyberPanel already installed, just configure
    systemctl restart lscpd
    
    # Get admin password (saved during AMI creation)
    ADMIN_PASS=$(cat /root/.cyberpanel_password 2>/dev/null || echo "admin")
    
    log "CyberPanel ready at https://$PUBLIC_IP:8090"
    log "Username: admin"
    log "Password: $ADMIN_PASS"
    ;;
    
  none)
    log "Clean server - no panel"
    ;;
esac

# 4. Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json << 'CWEOF'
{
  "metrics": {
    "namespace": "NeoVPS",
    "metrics_collected": {
      "cpu": {
        "measurement": [{"name": "cpu_usage_idle", "rename": "CPU_IDLE", "unit": "Percent"}],
        "totalcpu": false
      },
      "disk": {
        "measurement": [{"name": "used_percent", "rename": "DISK_USED", "unit": "Percent"}],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": [{"name": "mem_used_percent", "rename": "MEM_USED", "unit": "Percent"}]
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/neo-panel-setup.log",
            "log_group_name": "/neo-vps/$DOMAIN",
            "log_stream_name": "setup"
          }
        ]
      }
    }
  }
}
CWEOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

# 5. Update DynamoDB state
aws dynamodb put-item \
  --table-name neo-instances \
  --item '{
    "instance_id": {"S": "'$INSTANCE_ID'"},
    "domain": {"S": "'$DOMAIN'"},
    "panel": {"S": "'$PANEL'"},
    "public_ip": {"S": "'$PUBLIC_IP'"},
    "status": {"S": "active"},
    "setup_completed": {"S": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}
  }' \
  --region ${region}

# 6. Send SNS notification
aws sns publish \
  --topic-arn ${sns_topic_arn} \
  --subject "Server Ready: $DOMAIN" \
  --message "Server $DOMAIN is now active at $PUBLIC_IP" \
  --region ${region}

log "Setup complete!"