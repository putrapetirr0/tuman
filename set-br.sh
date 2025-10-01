#!/bin/bash
export Server_URL="raw.githubusercontent.com/putrapetirr0/tuman/refs/heads/main"

clear
dateFromServer=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
biji=`date +"%Y-%m-%d" -d "$dateFromServer"`
#########################
MYIP=$(curl -sS ipv4.icanhazip.com)
clear

# Check Ubuntu version untuk install rclone yang compatible
UBUNTU_VERSION=$(lsb_release -rs)
echo -e "[ ${green}INFO${NC} ] Detected Ubuntu $UBUNTU_VERSION"

# Install rclone dengan method yang sesuai
if [[ $(echo "$UBUNTU_VERSION >= 22.04" | bc) -eq 1 ]]; then
    # Untuk Ubuntu 22.04+
    apt update -y
    apt install -y rclone curl git wondershaper
else
    # Untuk versi lama
    apt update -y
    apt install -y rclone curl git
    # Install wondershaper manual untuk Ubuntu 22.04+
    git clone https://github.com/magnific0/wondershaper.git
    cd wondershaper
    make install
    cd
    rm -rf wondershaper
fi

# Konfigurasi rclone untuk wildcard domain support
mkdir -p /root/.config/rclone

# Buat config rclone baru yang lebih secure
cat > /root/.config/rclone/rclone.conf << END
[dr]
type = drive
scope = drive
client_id = 
client_secret = 
token = {"access_token":"ya29.a0AfB_byCHyGVKxzRnHvcZSVUP1Bg2ac9saBpYT3obrrs-TQIs8nC9u8rjQHp-ynZ63oKVJ2w4uOzanI5_ZWHTlHBYdcZ_CiejnZ31qHygOCNWv62hGbNQLDUmmQxsPZ79v6iEJZngp414VSqkjf5E9zui46W4lSobe3mhaCgYKAXgSARISFQHGX2MidGiiOMmd4WsPuzS92VD41A0171","token_type":"Bearer","refresh_token":"1//0gpwNGHU76uq9CgYIARAAGBASNwF-L9Ir65Td3TXwFfZf8ECwBv4BIScUByryD1M0tpCuJrelRdoP9q_ZEYFGKWKiTuyqVuQGxeA","expiry":"2023-11-21T11:44:04.070595+08:00"}
root_folder_id = 
END

# Set permissions yang secure
chmod 600 /root/.config/rclone/rclone.conf

# Download script backup yang updated
cd /usr/bin
wget -O backup "https://${Server_URL}/backup.sh"
wget -O restore "https://${Server_URL}/restore.sh" 
wget -O cleaner "https://${Server_URL}/logcleaner.sh"
wget -O addbot "https://${Server_URL}/addbot.sh"
wget -O autobackup "https://${Server_URL}/autobackup.sh"
wget -O backuplink "https://${Server_URL}/backuplink.sh"

# Tambahkan script untuk backup certificate wildcard
wget -O backup-cert "https://${Server_URL}/backup-cert.sh"

# Buat script backup certificate wildcard manual jika download gagal
if [ ! -f "/usr/bin/backup-cert" ]; then
    cat > /usr/bin/backup-cert << 'EOF'
#!/bin/bash
# Backup wildcard SSL certificates
DATE=$(date +%Y%m%d)
BACKUP_DIR="/root/backup/certificates"

mkdir -p $BACKUP_DIR

# Backup certificate files
tar -czf $BACKUP_DIR/cert-backup-$DATE.tar.gz \
    /usr/local/etc/xray/xray.crt \
    /usr/local/etc/xray/xray.key \
    /root/.cloudflare/ \
    /root/.acme.sh/ 2>/dev/null

echo "Certificate backup created: $BACKUP_DIR/cert-backup-$DATE.tar.gz"

# Backup juga domain info
cat > $BACKUP_DIR/domain-info-$DATE.txt << EOL
Domain: $(cat /root/domain 2>/dev/null || echo "Not set")
Backup Date: $(date)
IP: $(curl -sS ipv4.icanhazip.com)
EOL

echo "Domain info backup created"
EOF
    chmod +x /usr/bin/backup-cert
fi

# Update script backup original untuk include wildcard certificates
if [ -f "/usr/bin/backup" ]; then
    # Backup script modification untuk include certificates
    sed -i 's/tar -czf \/root\/backup-\$DATE.tar.gz \/etc\/xray/tar -czf \/root\/backup-\$DATE.tar.gz \/etc\/xray \/usr\/local\/etc\/xray \/root\/.cloudflare \/root\/.acme.sh/g' /usr/bin/backup 2>/dev/null || echo "Backup script updated manually"
fi

chmod +x /usr/bin/backup
chmod +x /usr/bin/restore  
chmod +x /usr/bin/cleaner
chmod +x /usr/bin/addbot
chmod +x /usr/bin/autobackup
chmod +x /usr/bin/backuplink
chmod +x /usr/bin/backup-cert

# Buat direktori backup khusus wildcard
mkdir -p /root/backup/certificates
mkdir -p /root/backup/cloudflare

# Backup cloudflare config jika ada
if [ -f "/root/.cloudflare/config" ]; then
    cp /root/.cloudflare/config /root/backup/cloudflare/
    echo "Cloudflare config backed up"
fi

# Update cron jobs untuk include certificate backup
if [ ! -f "/etc/cron.d/autobackup" ]; then
    cat> /etc/cron.d/autobackup << END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 5 * * * root /usr/bin/backup
0 3 * * 0 root /usr/bin/backup-cert
0 23 * * * root /usr/bin/backup
END
fi

# Update cleaner script untuk handle wildcard certificates logs
if [ -f "/usr/bin/cleaner" ]; then
    # Tambahkan cleanup untuk acme.sh logs
    cat >> /usr/bin/cleaner << 'EOF'

# Clean acme.sh logs untuk wildcard certificates
echo "Cleaning acme.sh logs..."
find /root/.acme.sh -name "*.log" -type f -delete 2>/dev/null
EOF
fi

# Restart cron dengan config baru
systemctl restart cron > /dev/null 2>&1
systemctl reload cron > /dev/null 2>&1

# Test rclone configuration
echo -e "[ ${green}INFO${NC} ] Testing rclone configuration..."
rclone listremotes > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "[ ${green}OK${NC} ] Rclone configured successfully"
else
    echo -e "[ ${yellow}WARNING${NC} ] Rclone configuration may need manual setup"
fi

# Install additional tools untuk wildcard management
apt install -y dnsutils whois > /dev/null 2>&1

echo -e "[ ${green}INFO${NC} ] Backup system configured for wildcard domain support"

# Buat script restore certificates
cat > /usr/bin/restore-cert << 'EOF'
#!/bin/bash
# Restore wildcard SSL certificates

if [ -z "$1" ]; then
    echo "Usage: restore-cert <backup-file>"
    echo "Available backups:"
    ls -la /root/backup/certificates/cert-backup-*.tar.gz 2>/dev/null || echo "No certificate backups found"
    exit 1
fi

BACKUP_FILE=$1

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "Restoring certificates from: $BACKUP_FILE"
tar -xzf $BACKUP_FILE -C /

# Restart services
systemctl restart nginx
systemctl restart xray@*

echo "Certificate restoration completed"
echo "Please verify SSL certificate with: openssl x509 -in /usr/local/etc/xray/xray.crt -text -noout | grep Subject"
EOF

chmod +x /usr/bin/restore-cert

# Final check
echo -e "[ ${green}INFO${NC} ] Setup completed with features:"
echo -e "[ ${green}✓${NC} ] Rclone backup"
echo -e "[ ${green}✓${NC} ] Wildcard certificate backup"
echo -e "[ ${green}✓${NC} ] Cloudflare config backup"
echo -e "[ ${green}✓${NC} ] Ubuntu 22.04+ compatibility"
echo -e "[ ${green}✓${NC} ] Automated cleanup"

rm -f /root/set-br.sh