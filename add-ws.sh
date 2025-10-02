#!/bin/bash
clear
dateFromServer=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
biji=`date +"%Y-%m-%d" -d "$dateFromServer"`
#########################
MYIP=$(wget -qO- ipv4.icanhazip.com);
MYIP=$(curl -s ipinfo.io/ip )
MYIP=$(curl -sS ipv4.icanhazip.com)
MYIP=$(curl -sS ifconfig.me )

red='\e[1;31m'
green='\e[0;32m'
NC='\e[0m'

clear
domain=$(cat /root/domain)
MYIP2=$(wget -qO- ipv4.icanhazip.com);

# TAMPILKAN INFORMASI WILDCARD
if [ -f "/root/.cloudflare/credentials" ]; then
    source /root/.cloudflare/credentials
    echo -e "${green}✅ Wildcard Domain: $DOMAIN${NC}"
    echo -e "${green}✅ Cloudflare CDN: Enabled${NC}"
fi

until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\\E[0;47;30m     Add XRAY Vmess WS Account     \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

                read -rp "Username : " -e user
                CLIENT_EXISTS=$(grep -w $user /usr/local/etc/xray/config.json | wc -l)

                if [[ ${CLIENT_EXISTS} == '1' ]]; then
clear
		                echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
                        echo -e "\\E[0;47;30m     Add XRAY Vmess WS Account     \E[0m"
                        echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
                        echo ""
                        echo "A client with the specified name was already created, please choose another name."
                        echo ""
                        echo -e "═══════════════════"
                        read -n 1 -s -r -p "Press any key to back on menu"
                        menu
                fi
        done

# UPDATE BUG ADDRESS LOGIC SAMA SEPERTI VLESS
read -p "Bug Address (Example: www.google.com) : " address
read -p "Bug SNI/Host (Example : m.facebook.com) : " hst
read -p "Expired (days) : " masaaktif

if [[ $address == "" ]]; then
    sts=""
    display_domain="$domain"
else
    sts="${address}."
    display_domain="${address}.${domain}"
fi

if [[ $hst == "" ]]; then
    sni=$domain
else
    sni=$hst
fi

uuid=$(cat /proc/sys/kernel/random/uuid)
exp=`date -d "$masaaktif days" +"%Y-%m-%d"`
hariini=`date -d "0 days" +"%Y-%m-%d"`
sed -i '/#tls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","alterId": '"0"',"email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#none$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","alterId": '"0"',"email": "'""$user""'"' /usr/local/etc/xray/none.json

cat> /usr/local/etc/xray/$user-tls.json << EOF
      {
      "v": "2",
      "ps": "XRAY_VMESS_TLS_${user}",
      "add": "${sts}${domain}",
      "port": "443",
      "id": "${uuid}",
      "aid": "0",
      "net": "ws",
      "path": "/vmess-tls",
      "type": "none",
      "host": "${domain}",
      "tls": "tls",
      "sni": "${sni}"
}
EOF

cat> /usr/local/etc/xray/$user-none.json << EOF
      {
      "v": "2",
      "ps": "XRAY_VMESS_NTLS_${user}",
      "add": "${sts}${domain}",
      "port": "80",
      "id": "${uuid}",
      "aid": "0",
      "net": "ws",
      "path": "/vmess-ntls",
      "type": "none",
      "host": "${domain}",
      "tls": "none"
}
EOF

vmess_base641=$( base64 -w 0 <<< $vmess_json1)
vmess_base642=$( base64 -w 0 <<< $vmess_json2)
vmesslink1="vmess://$(base64 -w 0 /usr/local/etc/xray/$user-tls.json)"
vmesslink2="vmess://$(base64 -w 0 /usr/local/etc/xray/$user-none.json)"

# Load Bot Token and Chat ID
BOT_TOKEN="$(sed '/^$/d' /home/botdet)"
CHAT_ID="$(sed '/^$/d' /home/chatdet)"

# Pesan yang akan dikirim
message="
════[XRAY VMESS WS]═════
Remarks           : ${user}
Domain            : ${domain}
IP/Host           : ${MYIP}
Port TLS          : 443
Port None TLS     : 80, 8080, 8880
ID                : \`${uuid}\`
AlterId           : 0
Security          : Auto
Network           : WS
Path TLS          : /vmess-tls
Path NTLS         : /vmess-ntls
═══════════════════
Link WS TLS       : \`${vmesslink1}\`
═══════════════════
Link WS None TLS  : \`${vmesslink2}\`
═══════════════════
Created On        : $hariini
Expired On        : $exp
═══════════════════
"

# Function to send a message to Telegram
send_message() {
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=${message}" \
    -d "parse_mode=Markdown"
}

# Kirim pesan
send_message "$message"

systemctl restart xray.service
systemctl restart xray@none.service
service cron restart
clear

# UPDATE OUTPUT INFORMATION
clear
echo -e ""
echo -e "════[XRAY VMESS WS]═════"
echo -e "Remarks           : ${user}"
echo -e "Domain            : ${domain}"
if [ -f "/root/.cloudflare/credentials" ]; then
    echo -e "Wildcard          : *.${domain}"
    echo -e "Cloudflare CDN    : ✅ Enabled"
fi
echo -e "IP/Host           : ${MYIP}"
echo -e "Port TLS          : 443"
echo -e "Port None TLS     : 80, 8080, 8880"
echo -e "ID                : ${uuid}"
echo -e "AlterId           : 0"
echo -e "Security          : Auto"
echo -e "Network           : WS"
echo -e "Path TLS          : /vmess-tls"
echo -e "Path NTLS         : /vmess-ntls"
echo -e "Bug Address       : ${display_domain}"
echo -e "SNI               : ${sni}"
echo -e "═══════════════════"
echo -e ""
echo -e "Script Mod By DELLZ"
echo ""
read -p "$( echo -e "Press ${orange}[ ${NC}${green}Enter${NC} ${CYAN}]${NC} Back to menu . . .") "
menu
