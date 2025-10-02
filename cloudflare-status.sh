#!/bin/bash
source /root/.cloudflare/credentials

echo -e "Cloudflare Status"
echo -e "================="
echo -e "Domain: $DOMAIN"
echo -e "Zone ID: $ZONE_ID"
echo -e "Email: $CF_EMAIL"

# Cek DNS records
echo -e "\nDNS Records:"
curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
    -H "X-Auth-Email: $CF_EMAIL" \
    -H "X-Auth-Key: $CF_API_KEY" \
    -H "Content-Type: application/json" | jq -r '.result[] | "\(.name) -> \(.content) (Proxied: \(.proxied))"'