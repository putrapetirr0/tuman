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

# TAMPILKAN INFORMASI DOMAIN WILDCARD JIKA ADA
if [ -f "/root/.cloudflare/credentials" ]; then
    source /root/.cloudflare/credentials
    echo -e "${green}✅ Wildcard Domain: $DOMAIN${NC}"
    echo -e "${green}✅ Cloudflare CDN: Enabled${NC}"
fi

until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
		echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo -e "\\E[0;47;30m     Add XRAY Vless WS Account     \E[0m"
        echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

		read -rp "Username : " -e user
		CLIENT_EXISTS=$(grep -w $user /usr/local/etc/xray/vless.json | wc -l)

		if [[ ${CLIENT_EXISTS} == '1' ]]; then
clear
		    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
            echo -e "\\E[0;47;30m      Add XRAY Vless Account       \E[0m"
            echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
			echo ""
			echo "A client with the specified name was already created, please choose another name."
			echo ""
			read -n 1 -s -r -p "Press any key to back on menu"
			menu
		fi
	done

# UPDATE BUG ADDRESS UNTUK WILDCARD
read -p "Bug Address (Example: www.google.com) : " address
read -p "Bug SNI/Host (Example : m.facebook.com) : " hst
read -p "Expired (days) : " masaaktif

# LOGIC BUG ADDRESS YANG LEBIH BAIK
if [[ $address == "" ]]; then
    # Jika tidak pakai bug address, gunakan domain utama
    sts=""
    display_domain="$domain"
else
    # Jika pakai bug address, tambahkan sebagai subdomain
    sts="${address}."
    display_domain="${address}.${domain}"
fi

# LOGIC SNI YANG LEBIH BAIK  
if [[ $hst == "" ]]; then
    # Jika tidak pakai custom SNI, gunakan domain
    sni=$domain
else
    # Jika pakai custom SNI
    sni=$hst
fi

uuid=$(cat /proc/sys/kernel/random/uuid)
exp=`date -d "$masaaktif days" +"%Y-%m-%d"`
hariini=`date -d "0 days" +"%Y-%m-%d"`

sed -i '/#tls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/vless.json
sed -i '/#none$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/vnone.json

# UPDATE LINK GENERATION UNTUK WILDCARD
vlesslink1="vless://${uuid}@${sts}${domain}:443?type=ws&encryption=none&security=tls&host=${domain}&path=/vless-tls&allowInsecure=1&sni=${sni}#XRAY_VLESS_TLS_${user}"
vlesslink2="vless://${uuid}@${sts}${domain}:80?type=ws&encryption=none&security=none&host=${domain}&path=/vless-ntls#XRAY_VLESS_NTLS_${user}"

# ... rest of existing YAML config code ...

# UPDATE BAGIAN OUTPUT INFORMATION
clear
echo -e ""
echo -e "════[XRAY VLESS WS]═════"
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
echo -e "Path TLS          : /vless-tls"
echo -e "Path NTLS         : /vless-ntls"
echo -e "Bug Address       : ${display_domain}"
echo -e "SNI               : ${sni}"
echo -e "═══════════════════"
echo -e "Link WS TLS       : ${vlesslink1}"
echo -e "═══════════════════"
echo -e "Link WS None TLS  : ${vlesslink2}"
echo -e "═══════════════════"
echo -e "Created On        : $hariini"
echo -e "Expired On        : $exp"
echo -e "═══════════════════"
echo -e ""
echo -e "Script Mod By DELLZ"
echo ""
read -p "$( echo -e "Press ${orange}[ ${NC}${green}Enter${NC} ${CYAN}]${NC} Back to menu . . .") "
menu