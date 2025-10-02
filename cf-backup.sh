#!/bin/bash
# Backup Cloudflare Configuration
source /root/.cloudflare/credentials

BACKUP_DIR="/root/cloudflare-backup"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "Backing up Cloudflare configuration..."

# Backup DNS records
curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
    -H "X-Auth-Email: $CF_EMAIL" \
    -H "X-Auth-Key: $CF_API_KEY" \
    -H "Content-Type: application/json" > $BACKUP_DIR/dns_records_$DATE.json

# Backup zone settings
curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID" \
    -H "X-Auth-Email: $CF_EMAIL" \
    -H "X-Auth-Key: $CF_API_KEY" \
    -H "Content-Type: application/json" > $BACKUP_DIR/zone_$DATE.json

echo "Cloudflare backup completed: $BACKUP_DIR/"