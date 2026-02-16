#!/bin/bash
PANEL="$1"
IP="$2"

case "$PANEL" in
  cyberpanel)
    curl -k -s -o /dev/null -w "%{http_code}" "https://$IP:8090" | grep -q "200\|302"
    ;;
  cpanel)
    curl -k -s -o /dev/null -w "%{http_code}" "https://$IP:2087" | grep -q "200\|302"
    ;;
esac
