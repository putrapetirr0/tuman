#!/bin/bash

red='\e[1;31m'
green='\e[0;32m'
purple='\e[0;35m'
orange='\e[0;33m'
NC='\e[0m'

clear
IP=$(curl -sS ipv4.icanhazip.com)
date=$(date +"%Y-%m-%d-%H:%M:%S")
domain=$(cat /root/domain)

# Read bot token and chat ID
BOT_TOKEN=$(cat /home/bot)
CHAT_ID=$(cat /home/chat)

send_to_telegram() {
    local message=$1
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$message" > /dev/null
}

echo -e "[ ${green}INFO${NC} ] Processing . . . "
mkdir -p /root/backup
sleep 1
clear
echo " Please Wait VPS Data Backup In Progress . . . "
cp -r /usr/local/etc/xray/*.json /root/backup/ >/dev/null 2>&1
cp -r /root/domain /root/backup/ &> /dev/null
cp -r /home/vps/public_html /root/backup/public_html
cp -r /etc/cron.d /root/backup/cron.d &> /dev/null
cp -r /etc/crontab /root/backup/crontab &> /dev/null

cd /root
zip -r backup.zip backup > /dev/null 2>&1
rclone copy /root/backup.zip dr:backup/
url=$(rclone link dr:backup/backup.zip)
id=(`echo $url | grep '^https' | cut -d'=' -f2`)
link="https://drive.google.com/u/4/uc?id=${id}&export=download"

# Send link to Telegram
message="VPS Backup Completed:
- IP: $IP
- Domain: $domain
- Date: $date
Backup Link:
$link"
send_to_telegram "$message"

# Cleanup
rm -rf /root/backup
rm -f /root/backup.zip

echo ""
echo -e "[ ${green}INFO${NC} ] Backup completed and link sent to Telegram."
read -p "$( echo -e "Press ${orange}[ ${NC}${green}Enter${NC} ${CYAN}]${NC} Back to menu . . .") "
menu
