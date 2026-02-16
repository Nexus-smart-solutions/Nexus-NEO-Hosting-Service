#!/bin/bash
DOMAIN="$1"
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  echo "Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES"
  
  if ./automation/provision-customer.sh \
      --domain "$DOMAIN" \
      --email "$EMAIL" \
      --panel "$PANEL" \
      --os "$OS"; then
    echo "✅ Success!"
    exit 0
  else
    echo "❌ Failed, retrying..."
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep 60
  fi
done

echo "❌ All retries failed"
# Send admin alert
exit 1
