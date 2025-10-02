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

# Tambahkan di bagian awal setelah clear domain
if [ -f "/root/.cloudflare/credentials" ]; then
    source /root/.cloudflare/credentials
    echo -e "${green}✅ Wildcard Domain: $DOMAIN${NC}"
    echo -e "${green}✅ Cloudflare CDN: Enabled${NC}"
fi

until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
		echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo -e "\\E[0;47;30m  Add XRAY TROJAN TCP XTLS Account  \E[0m"
        echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
		read -rp "Username : " -e user
		CLIENT_EXISTS=$(grep -w $user /usr/local/etc/xray/xtrojan.json | wc -l)

		if [[ ${CLIENT_EXISTS} == '1' ]]; then
clear
		echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo -e "\\E[0;47;30m  Add XRAY TROJAN TCP XTLS Account  \E[0m"
        echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
		echo ""
		echo "A client with the specified name was already created, please choose another name."
		echo ""
		read -n 1 -s -r -p "Press any key to back on menu"
		menu
		fi
	done
	
# UPDATE BUG ADDRESS LOGIC
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
hariini=`date -d "0 days" +"%Y-%m-%d"`
exp=`date -d "$masaaktif days" +"%Y-%m-%d"`

sed -i '/#trojan-xtls$/a\### '"$user $exp"'\
},{"password": "'""$uuid""'","flow": "xtls-rprx-direct","email": "'""$user""'"' /usr/local/etc/xray/xtrojan.json

trojanlink1="trojan://${uuid}@${sts}${domain}:443?allowInsecure=1&security=xtls&headerType=none&type=tcp&flow=xtls-rprx-direct&sni=${sni}#TROJAN_DIRECT_${user}"
trojanlink2="trojan://${uuid}@${sts}${domain}:443?allowInsecure=1&security=xtls&headerType=none&type=tcp&flow=xtls-rprx-direct-udp443&sni=${sni}#TROJAN_DIRECTUDP443_${user}"
trojanlink3="trojan://${uuid}@${sts}${domain}:443?allowInsecure=1&security=xtls&headerType=none&type=tcp&flow=xtls-rprx-splice&sni=${sni}#TROJAN_SPLICE_${user}"
trojanlink4="trojan://${uuid}@${sts}${domain}:443?allowInsecure=1&security=xtls&headerType=none&type=tcp&flow=xtls-rprx-splice-udp443&sni=${sni}#TROJAN_SPLICEUDP443_${user}"

systemctl restart xray@xtrojan.service
service cron restart

clear
echo -e ""
echo -e "════[XRAY TROJAN TCP XTLS]═════"
echo -e "Remarks              : ${user}"
echo -e "Domain               : ${domain}"
if [ -f "/root/.cloudflare/credentials" ]; then
    echo -e "Wildcard          : *.${domain}"
    echo -e "Cloudflare CDN    : ✅ Enabled"
fi
echo -e "IP/Host              : ${MYIP}"
echo -e "Password             : ${uuid}"
echo -e "Port Direct          : 443"
echo -e "Port Splice          : 443"
echo -e "Encryption           : None"
echo -e "Network              : TCP"
echo -e "Security             : XTLS"
echo -e "Flow                 : Direct & Splice"
echo -e "AllowInsecure        : True/Allow"
echo -e "═══════════════════"
echo -e "Link Direct          : ${trojanlink1}"
echo -e "═══════════════════"
echo -e "Link Direct UDP 443  : ${trojanlink2}"
echo -e "═══════════════════"
echo -e "Link Splice          : ${trojanlink3}"
echo -e "═══════════════════"
echo -e "Link Splice UDP 443  : ${trojanlink4}"
echo -e "═══════════════════"
echo -e "Created On           : $hariini"
echo -e "Expired On           : $exp"
echo -e "═══════════════════"
echo -e ""
echo -e ""
echo -e "Script Mod By DELLZ"
echo ""
read -p "$( echo -e "Press ${orange}[ ${NC}${green}Enter${NC} ${CYAN}]${NC} Back to menu . . .") "
menu
