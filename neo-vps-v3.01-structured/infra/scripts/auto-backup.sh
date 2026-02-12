#!/bin/bash

INSTANCE_ID=$1
DOMAIN=$2
BACKUP_BUCKET="neo-backups-$(aws sts get-caller-identity --query Account --output text)"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 1. Create EBS snapshot
log "Creating EBS snapshot for $INSTANCE_ID"

VOLUME_IDS=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].BlockDeviceMappings[*].Ebs.VolumeId' \
    --output text)

for VOLUME_ID in $VOLUME_IDS; do
    SNAPSHOT_ID=$(aws ec2 create-snapshot \
        --volume-id $VOLUME_ID \
        --description "Auto backup for $DOMAIN - $(date +%Y-%m-%d)" \
        --tag-specifications "ResourceType=snapshot,Tags=[{Key=Domain,Value=$DOMAIN},{Key=Type,Value=AutoBackup},{Key=Date,Value=$(date +%Y-%m-%d)}]" \
        --query 'SnapshotId' \
        --output text)
    
    log "✅ Created snapshot: $SNAPSHOT_ID for volume $VOLUME_ID"
done

# 2. Backup panel configs (if cPanel/CyberPanel)
log "Backing up panel configurations"

ssh -o StrictHostKeyChecking=no root@$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text) << 'ENDSSH'
    
# Backup cPanel accounts
if [ -d "/var/cpanel" ]; then
    /scripts/pkgacct --backup --all
    aws s3 sync /backup/cpbackup s3://$BACKUP_BUCKET/cpanel-backups/$DOMAIN/
fi

# Backup CyberPanel sites
if [ -d "/usr/local/lsws" ]; then
    tar -czf /tmp/cyberpanel-backup.tar.gz /home /usr/local/lsws/conf
    aws s3 cp /tmp/cyberpanel-backup.tar.gz s3://$BACKUP_BUCKET/cyberpanel-backups/$DOMAIN/$(date +%Y%m%d).tar.gz
fi

ENDSSH

log "✅ Backup complete for $DOMAIN"
