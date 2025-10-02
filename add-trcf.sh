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

until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${user_EXISTS} == '0' ]]; do
		echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
            echo -e "\\E[0;47;30m     Add XRAY Trojan WS Account    \E[0m"
        echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

		read -rp "Username : " -e user
		user_EXISTS=$(grep -w $user /usr/local/etc/xray/trojanws.json | wc -l)

		if [[ ${user_EXISTS} == '1' ]]; then
clear
		echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
            echo -e "\\E[0;47;30m     Add XRAY Trojan WS Account    \E[0m"
        echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
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
exp=`date -d "$masaaktif days" +"%Y-%m-%d"`
hariini=`date -d "0 days" +"%Y-%m-%d"`
sed -i '/#tr$/a\### '"$user $exp"'\
},{"password": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/trojanws.json
sed -i '/#trnone$/a\### '"$user $exp"'\
},{"password": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/trnone.json

trojanlink1="trojan://${uuid}@${domain}:443?type=ws&security=tls&host=${domain}&path=/trojan-tls&sni=${sni}#${user}"
trojanlink2="trojan://${uuid}@${domain}:80?type=ws&security=none&host=${domain}&path=/trojan-ntls#${user}"

#Restart service
systemctl restart xray@trojanws.service
systemctl restart xray@trnone.service
service cron restart
clear

# UPDATE OUTPUT INFORMATION
clear
echo -e ""
echo -e "═════[XRAY TROJAN WS]═════"
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
echo -e "Security          : TLS"
echo -e "Encryption        : None"
echo -e "Network           : WS"
echo -e "Path TLS          : /trojan-tls"
echo -e "Path NTLS         : /trojan-ntls"
echo -e "Bug Address       : ${display_domain}"
echo -e "SNI               : ${sni}"
echo -e "═══════════════════"
echo -e ""
echo -e "Script Mod By Dellz182"
echo ""
read -p "$( echo -e "Press ${orange}[ ${NC}${green}Enter${NC} ${CYAN}]${NC} Back to menu . . .") "
menu
