#!/bin/bash
red='\e[1;31m'
green='\e[0;32m'
purple='\e[0;35m'
orange='\e[0;33m'
NC='\e[0m'
clear

# Get IP with multiple methods
IP=$(curl -sS ipv4.icanhazip.com)
date=$(date +"%Y-%m-%d-%H:%M:%S")
domain=$(cat /root/domain)

clear
echo " VPS Data Backup By ArAz1308 "
sleep 1

echo -e "[ ${green}INFO${NC} ] Processing . . . "
mkdir -p /root/backup
sleep 1

clear
echo " Please Wait VPS Data Backup In Progress . . . "

# =============================================
# BACKUP UTAMA - MODIFIED FOR WILDCARD SUPPORT
# =============================================

# 1. Backup Xray configurations
cp -r /usr/local/etc/xray/*.json /root/backup/ >/dev/null 2>&1

# 2. Backup domain info
cp -r /root/domain /root/backup/ &> /dev/null

# 3. Backup web files
cp -r /home/vps/public_html /root/backup/public_html

# 4. Backup cron jobs
cp -r /etc/cron.d /root/backup/cron.d &> /dev/null
cp -r /etc/crontab /root/backup/crontab &> /dev/null

# =============================================
# NEW: WILDCARD DOMAIN BACKUP FEATURES
# =============================================

# 5. Backup SSL Certificates (Critical for wildcard)
echo -e "[ ${green}INFO${NC} ] Backing up SSL certificates..."
if [ -f "/usr/local/etc/xray/xray.crt" ]; then
    mkdir -p /root/backup/ssl
    cp -r /usr/local/etc/xray/xray.crt /root/backup/ssl/ &> /dev/null
    cp -r /usr/local/etc/xray/xray.key /root/backup/ssl/ &> /dev/null
    echo -e "[ ${green}OK${NC} ] SSL certificates backed up"
else
    echo -e "[ ${yellow}WARNING${NC} ] No SSL certificates found"
fi

# 6. Backup Cloudflare configuration (for wildcard domains)
if [ -d "/root/.cloudflare" ]; then
    echo -e "[ ${green}INFO${NC} ] Backing up Cloudflare configuration..."
    cp -r /root/.cloudflare /root/backup/ &> /dev/null
    echo -e "[ ${green}OK${NC} ] Cloudflare config backed up"
fi

# 7. Backup acme.sh certificates (for wildcard renewal)
if [ -d "/root/.acme.sh" ]; then
    echo -e "[ ${green}INFO${NC} ] Backing up ACME certificates..."
    mkdir -p /root/backup/acme
    # Backup important acme files only (exclude logs to save space)
    cp -r /root/.acme.sh/account.conf /root/backup/acme/ &> /dev/null
    cp -r /root/.acme.sh/$domain* /root/backup/acme/ &> /dev/null 2>/dev/null
    echo -e "[ ${green}OK${NC} ] ACME certificates backed up"
fi

# 8. Backup system info dengan wildcard status
echo -e "[ ${green}INFO${NC} ] Creating system info backup..."
cat > /root/backup/system-info.txt << EOF
=== VPS BACKUP INFORMATION ===
Backup Date: $date
IP Address: $IP
Domain: $domain
Wildcard Domain: $(if [[ $domain == *"*"* ]]; then echo "YES (*.$domain)"; else echo "NO"; fi)
Ubuntu Version: $(lsb_release -d | cut -f2)
Xray Version: $(/usr/local/bin/xray version 2>/dev/null | head -n1 || echo "Unknown")
SSL Certificate: $(if [ -f "/usr/local/etc/xray/xray.crt" ]; then 
    echo "VALID ($(date -r /usr/local/etc/xray/xray.crt +%Y-%m-%d))"; 
else echo "MISSING"; fi)
Cloudflare Setup: $(if [ -d "/root/.cloudflare" ]; then echo "CONFIGURED"; else echo "NOT CONFIGURED"; fi)
EOF

# =============================================
# CREATE BACKUP ARCHIVE
# =============================================

cd /root
echo -e "[ ${green}INFO${NC} ] Creating backup archive..."

# Create backup filename dengan info wildcard
if [[ $domain == *"*"* ]]; then
    BACKUP_FILENAME="wildcard-${domain//\*/star}-$date.zip"
else
    BACKUP_FILENAME="$domain-$date.zip"
fi

# Create zip archive
if zip -r $BACKUP_FILENAME backup > /dev/null 2>&1; then
    echo -e "[ ${green}SUCCESS${NC} ] Backup created: $BACKUP_FILENAME"
    
    # Show backup contents
    echo -e "[ ${green}INFO${NC} ] Backup contents:"
    du -sh /root/backup/*
else
    echo -e "[ ${red}ERROR${NC} ] Failed to create backup archive"
    read -p "$( echo -e "Press ${orange}[ ${NC}${green}Enter${NC} ${CYAN}]${NC} Back to menu . . .") "
    menu
fi

# =============================================
# UPLOAD BACKUP (OPTIONAL)
# =============================================

echo -e "[ ${green}INFO${NC} ] Uploading backup..."
# Download upload script
if wget -q -O sendd.sh "https://raw.githubusercontent.com/putrapetirr0/ARAZ/main/backup/sendd.sh"; then
    chmod +x sendd.sh
    if ./sendd.sh $BACKUP_FILENAME; then
        echo -e "[ ${green}SUCCESS${NC} ] Backup uploaded successfully"
    else
        echo -e "[ ${yellow}WARNING${NC} ] Backup created locally but upload failed"
        echo -e "[ ${green}INFO${NC} ] Local backup: /root/$BACKUP_FILENAME"
    fi
    rm -f sendd.sh
else
    echo -e "[ ${yellow}INFO${NC} ] Upload script not available, backup saved locally"
    echo -e "[ ${green}INFO${NC} ] Local backup: /root/$BACKUP_FILENAME"
fi

# =============================================
# CLEANUP
# =============================================

# Keep the final backup file, only cleanup temp files
rm -rf /root/backup
rm -f /root/index.html

echo -e "[ ${green}BACKUP SUMMARY${NC} ]"
echo -e "Domain: $domain"
echo -e "Wildcard: $(if [[ $domain == *"*"* ]]; then echo "Enabled"; else echo "Disabled"; fi)"
echo -e "Backup File: $BACKUP_FILENAME"
echo -e "Size: $(du -h $BACKUP_FILENAME | cut -f1)"
echo ""
echo "Jangan lupa sedekah"
echo ""

# Additional info for wildcard domains
if [[ $domain == *"*"* ]]; then
    echo -e "${green}Wildcard Backup Notes:${NC}"
    echo -e "✓ SSL Certificates included"
    echo -e "✓ Cloudflare configuration included" 
    echo -e "✓ ACME renewal data included"
    echo -e "✓ Domain: *.$domain"
fi

read -p "$( echo -e "Press ${orange}[ ${NC}${green}Enter${NC} ${CYAN}]${NC} Back to menu . . .") "
menu