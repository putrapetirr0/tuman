#!/bin/bash
# My Telegram : https://t.me/araz1308
# ==========================================
# Color
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'
# ==========================================
# Getting
clear
IP=$(wget -qO- ipinfo.io/ip);
date=$(date +"%Y-%m-%d");
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[ON]${Font_color_suffix}"
Error="${Red_font_prefix}[OFF]${Font_color_suffix}"
cek=$(grep -c -E "^# BEGIN_Backup" /etc/crontab)
if [[ "$cek" = "1" ]]; then
sts="${Info}"
else
sts="${Error}"
fi
function start() {
BOT_TOKEN=$(cat /home/bot)
if [[ "$BOT_TOKEN" = "" ]]; then
echo "Please enter your bot token"
read -rp "BOT_TOKEN : " -e BOT_TOKEN
cat <<EOF>>/home/bot
$BOT_TOKEN
EOF
fi
CHAT_ID=$(cat /home/chat)
if [[ "$CHAT_ID" = "" ]]; then
echo "Please enter your chat id"
read -rp "CHAT_ID : " -e CHAT_ID
cat <<EOF>>/home/chat
$CHAT_ID
EOF
fi
cat << EOF >> /etc/crontab
# BEGIN_Backup
0 */5 * * * root /usr/bin/backup
# END_Backup
EOF
service cron restart > /dev/null 2>&1
sleep 1
echo " Please Wait"
clear
echo " Autobackup Has Been Started"
echo " Data backup setiap 5 jam"
exit 0
}
function stop() {
BOT_TOKEN=$(cat /home/bot)
sed -i "/^$BOT_TOKEN/d" /home/bot
sed -i "/^# BEGIN_Backup/,/^# END_Backup/d" /etc/crontab
CHAT_ID=$(cat /home/chat)
sed -i "/^$CHAT_ID/d" /home/chat
sed -i "/^# BEGIN_Backup/,/^# END_Backup/d" /etc/crontab
service cron restart > /dev/null 2>&1
sleep 1
echo " Please Wait"
clear
echo " Autobackup Has Been Stopped"
exit 0
}

function gantipenerima() {
rm -rf /home/bot
rm -rf /home/chat
}
clear
echo -e "=============================="
echo -e "   Autobackup Telegram $sts     "
echo -e "=============================="
echo -e "1. Start Autobackup Telegram"
echo -e "2. Stop Autobackup Telegram"
echo -e "3. Hapus Grup Telegram"
echo -e "=============================="
read -rp "Please Enter The Correct Number : " -e num
case $num in
1)
start
;;
2)
stop
;;
3)
gantipenerima
;;
*)
clear
;;
esac
