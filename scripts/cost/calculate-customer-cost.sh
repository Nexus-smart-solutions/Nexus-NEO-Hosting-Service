#!/bin/bash
CUSTOMER_ID="$1"
MONTH="${2:-$(date +%Y-%m)}"

echo "Calculating costs for $CUSTOMER_ID in $MONTH..."

# Get instance ID
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Customer,Values=$CUSTOMER_ID" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

# Get costs from Cost Explorer
aws ce get-cost-and-usage \
  --time-period Start=${MONTH}-01,End=${MONTH}-31 \
  --granularity MONTHLY \
  --filter file://filter.json \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Customer

# Calculate:
# - EC2 cost
# - EBS cost
# - RDS cost (if exists)
# - Data transfer
# - Total
# - Margin (price - cost)

echo "Summary:"
echo "EC2:      $EC2_COST"
echo "EBS:      $EBS_COST"
echo "RDS:      $RDS_COST"
echo "Data:     $DATA_COST"
echo "───────────────────"
echo "Total:    $TOTAL_COST"
echo "Price:    $PLAN_PRICE"
echo "Margin:   $MARGIN ($MARGIN_PCT%)"
