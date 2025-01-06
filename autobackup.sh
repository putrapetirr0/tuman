#!/bin/bash
# My Telegram : https://t.me/araz1308
# ==========================================
# Color

# Informasi dan Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
Info="${GREEN}[ON]${NC}"
Error="${RED}[OFF]${NC}"

# Mendapatkan IP dan Tanggal
IP=$(wget -qO- ipinfo.io/ip)
date=$(date +"%Y-%m-%d")

# Fungsi untuk Menambahkan Cron Job dengan Cek Duplikasi
function add_cron_job() {
    # Hapus entri lama jika ada
    sed -i "/^# BEGIN_Backup/,/^# END_Backup/d" /etc/crontab

    # Tambahkan entri baru
    cat <<EOF >> /etc/crontab
# BEGIN_Backup
0 */5 * * * root /usr/bin/backup > /dev/null 2>&1
0 */5 * * * root /usr/bin/backuplink > /dev/null 2>&1
# END_Backup
EOF
    echo "Backup cron job successfully added or updated."
}

# Fungsi Start
function start() {
    # Periksa apakah file /home/bot dan /home/chat sudah ada
    if [[ ! -f /home/bot ]]; then
        echo "Please enter your bot token:"
        read -rp "BOT_TOKEN: " BOT_TOKEN
        echo "$BOT_TOKEN" > /home/bot
        chmod 600 /home/bot
    fi

    if [[ ! -f /home/chat ]]; then
        echo "Please enter your chat ID:"
        read -rp "CHAT_ID: " CHAT_ID
        echo "$CHAT_ID" > /home/chat
        chmod 600 /home/chat
    fi

    # Tambahkan cron job
    add_cron_job

    # Restart layanan cron
    systemctl restart cron || { echo "Failed to restart cron service."; exit 1; }

    # Konfirmasi
    echo -e "${GREEN}Autobackup has been started.${NC}"
    echo "Data backup will run every 5 hours."
}

# Fungsi Stop
function stop() {
    # Hapus entri backup dari crontab
    sed -i "/^# BEGIN_Backup/,/^# END_Backup/d" /etc/crontab

    # Restart layanan cron
    systemctl restart cron || { echo "Failed to restart cron service."; exit 1; }

    # Konfirmasi
    echo -e "${RED}Autobackup has been stopped.${NC}"
}

# Fungsi Hapus Konfigurasi Telegram
function reset_telegram() {
    rm -f /home/bot /home/chat
    echo "Telegram configuration has been reset. You can configure it again by restarting Autobackup."
}

# Menu Utama
clear
cek=$(grep -c -E "^# BEGIN_Backup" /etc/crontab)
sts="${Info}"
if [[ "$cek" -ne 1 ]]; then
    sts="${Error}"
fi

echo -e "=============================="
echo -e "   Autobackup Telegram $sts"
echo -e "=============================="
echo -e "1. Start Autobackup Telegram"
echo -e "2. Stop Autobackup Telegram"
echo -e "3. Reset Telegram Configuration"
echo -e "4. Exit"
echo -e "=============================="
read -rp "Please Enter The Correct Number: " num

case $num in
1)
    start
    ;;
2)
    stop
    ;;
3)
    reset_telegram
    ;;
4)
    echo "Exiting..."
    exit 0
    ;;
*)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

