#!/bin/bash
red='\e[1;31m'
green='\e[0;32m'
purple='\e[0;35m'
orange='\e[0;33m'
NC='\e[0m'
clear
IP=$(wget -qO- icanhazip.com);
IP=$(curl -s ipinfo.io/ip )
IP=$(curl -sS ipv4.icanhazip.com)
IP=$(curl -sS ifconfig.me )
date=$(date +"%Y-%m-%d-%H:%M:%S")
domain=$(cat /root/domain)
clear
echo " VPS Data Backup By ArAz1308 "
sleep 1
#echo ""
#echo -e "[ ${green}INFO${NC} ] Please Insert Password To Secure Backup Data ."
#echo ""
#read -rp "Enter password : " -e InputPass
#clear
#sleep 1
#if [[ -z $InputPass ]]; then
#exit 0
#fi
echo -e "[ ${green}INFO${NC} ] Processing . . . "
mkdir -p /root/backup
sleep 1
clear
echo " Please Wait VPS Data Backup In Progress . . . "
#cp -r /root/.acme.sh /root/backup/ &> /dev/null
#cp -r /var/lib/premium-script/ /root/backup/premium-script
#cp -r /usr/local/etc/xray /root/backup/xray
cp -r /usr/local/etc/xray/*.json /root/backup/ >/dev/null 2>&1
cp -r /root/domain /root/backup/ &> /dev/null
cp -r /home/vps/public_html /root/backup/public_html
cp -r /etc/cron.d /root/backup/cron.d &> /dev/null
cp -r /etc/crontab /root/backup/crontab &> /dev/null
cd /root
zip -r $IP-backup-data.zip backup > /dev/null 2>&1
wget send.sh "https://raw.githubusercontent.com/putrapetirr0/ARAZ/main/backup/sendd.sh"
chmod +x sendd.sh
bash sendd.sh $IP-backup-data.zip
rm -rf /root/backup
rm -r /root/$IP-backup-data.zip
rm -r /root/sendd.sh
rm -r /root/index.html
echo "Jangan lupa sedekah"
echo ""
read -p "$( echo -e "Press ${orange}[ ${NC}${green}Enter${NC} ${CYAN}]${NC} Back to menu . . .") "
menu
