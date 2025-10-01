#!/bin/bash
# Backup wildcard SSL certificates
DATE=$(date +%Y%m%d)
BACKUP_DIR="/root/backup/certificates"

mkdir -p $BACKUP_DIR

echo "Backing up wildcard certificates..."

# Backup certificate files
if tar -czf $BACKUP_DIR/cert-backup-$DATE.tar.gz \
    /usr/local/etc/xray/xray.crt \
    /usr/local/etc/xray/xray.key \
    /root/.cloudflare/ \
    /root/.acme.sh/ 2>/dev/null; then
    
    echo "Certificate backup created: $BACKUP_DIR/cert-backup-$DATE.tar.gz"
else
    echo "Warning: Some certificate files may be missing"
fi

# Backup domain info
cat > $BACKUP_DIR/domain-info-$DATE.txt << EOL
Domain: $(cat /root/domain 2>/dev/null || echo "Not set")
Backup Date: $(date)
IP: $(curl -sS ipv4.icanhazip.com)
Wildcard: $(if [[ $(cat /root/domain 2>/dev/null) == *"*"* ]]; then echo "Yes"; else echo "No"; fi)
EOL

echo "Backup completed successfully"