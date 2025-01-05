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
rm -rf /home/botdet
rm -rf /home/chatdet
clear
BOT_TOKEN=$(cat /home/botdet)
if [[ "$BOT_TOKEN" = "" ]]; then
echo "Please enter your bot token"
read -rp "BOT_TOKEN : " -e BOT_TOKEN
cat <<EOF>>/home/botdet
$BOT_TOKEN
EOF
fi
CHAT_ID=$(cat /home/chatdet)
if [[ "$CHAT_ID" = "" ]]; then
echo "Please enter your chat id"
read -rp "CHAT_ID : " -e CHAT_ID
cat <<EOF>>/home/chatdet
$CHAT_ID
EOF
fi
clear
