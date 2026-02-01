#!/bin/bash
set -e

DOMAIN="${domain}"
EMAIL="${email}"

echo "Setting up SSL for $DOMAIN..."

# Wait for cPanel installation
while [ ! -f /usr/local/cpanel/cpanel ]; do
  echo "Waiting for cPanel..."
  sleep 10
done

# Install AutoSSL
/usr/local/cpanel/bin/autossl_check --all

echo "SSL setup complete!"
