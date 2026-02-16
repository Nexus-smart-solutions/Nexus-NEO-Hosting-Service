#!/bin/bash
echo "Testing backup restore..."

# 1. Create test instance
DOMAIN="test-restore-$(date +%s).com"

# 2. Provision
./automation/provision-customer.sh \
  --domain "$DOMAIN" \
  --os almalinux-8 \
  --panel cyberpanel

# 3. Get instance ID
INSTANCE_ID=$(terraform output -raw instance_id)

# 4. Create test data
ssh root@$(terraform output -raw elastic_ip) << 'EOF'
echo "Test file" > /root/test-backup.txt
EOF

# 5. Create snapshot
aws ec2 create-snapshot \
  --volume-id $(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' \
    --output text) \
  --description "Test snapshot"

SNAPSHOT_ID=$(...output...)

# 6. Wait for snapshot
aws ec2 wait snapshot-completed --snapshot-ids "$SNAPSHOT_ID"

# 7. Destroy original
terraform destroy -auto-approve

# 8. Restore from snapshot
# Create volume from snapshot
# Attach to new instance
# Mount and verify

# 9. Check test file exists
ssh root@NEW_IP "cat /root/test-backup.txt"
