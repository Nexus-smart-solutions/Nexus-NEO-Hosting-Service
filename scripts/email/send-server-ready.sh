#!/bin/bash
CUSTOMER_EMAIL="$1"
DOMAIN="$2"

# Get server details from Terraform
cd "environments/customers/${DOMAIN//./-}"
SERVER_IP=$(terraform output -raw elastic_ip)
PANEL_URL=$(terraform output -raw panel_url)

# Replace template variables
sed -e "s/{{domain}}/$DOMAIN/g" \
    -e "s/{{server_ip}}/$SERVER_IP/g" \
    -e "s/{{panel_url}}/$PANEL_URL/g" \
    templates/emails/server-ready.html > /tmp/email.html

# Send via SES or SMTP
aws ses send-email \
  --from "noreply@nexus-dxb.com" \
  --to "$CUSTOMER_EMAIL" \
  --subject "Your NEO VPS Server is Ready!" \
  --html file:///tmp/email.html
