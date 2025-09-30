#!/bin/bash
clear
DEFBOLD='\e[39;1m'
RB='\e[31;1m'
GB='\e[32;1m'
YB='\e[33;1m'
BB='\e[34;1m'
MB='\e[35;1m'
CB='\e[35;1m'
WB='\e[37;1m'
red='\e[1;31m'
green='\e[0;32m'
purple='\e[0;35m'
orange='\e[0;33m'
NC='\e[0m'

# Cloudflare Configuration
export CF_EMAIL=""
export CF_API_KEY=""

dateFromServer=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
biji=`date +"%Y-%m-%d" -d "$dateFromServer"`

MYIP=$(curl -sS ipv4.icanhazip.com)
echo "Checking VPS"

clear
red='\e[1;31m'
green='\e[0;32m'
yell='\e[1;33m'
tyblue='\e[1;36m'
NC='\e[0m'
purple() { echo -e "\\033[35;1m${*}\\033[0m"; }
tyblue() { echo -e "\\033[36;1m${*}\\033[0m"; }
yellow() { echo -e "\\033[33;1m${*}\\033[0m"; }
green() { echo -e "\\033[32;1m${*}\\033[0m"; }
red() { echo -e "\\033[31;1m${*}\\033[0m"; }

if [ "${EUID}" -ne 0 ]; then
    echo "You need to run this script as root"
    exit 1
fi

if [ "$(systemd-detect-virt)" == "openvz" ]; then
    echo "OpenVZ is not supported"
    exit 1
fi

secs_to_human() {
    echo "Installation time : $(( ${1} / 3600 )) hours $(( (${1} / 60) % 60 )) minutes $(( ${1} % 60 )) seconds"
}
start=$(date +%s)

echo -e "[ ${green}INFO${NC} ] Preparing the autoscript installation ~"
apt install git curl -y >/dev/null 2>&1
echo -e "[ ${green}INFO${NC} ] Installation file is ready to begin !"
sleep 1

if [ -f "/usr/local/etc/xray/domain" ]; then
echo "Script Already Installed"
exit 0
fi

mkdir /var/lib/premium-script;
mkdir /var/lib/crot-script;
clear

echo -e "${red}    ♦️${NC} ${green} CLOUDFLARE + WILDCARD SETUP     ${NC}"
echo -e "${red}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m${NC}"
echo "1. Standard Domain (Auto SSL)"
echo "2. Wildcard Domain with Cloudflare (*.domain.com)"
echo -e "${red}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m${NC}"
read -rp "Choose Your Domain Installation : " dom 

if test $dom -eq 1; then
    read -rp "Enter Your Domain : " domen 
    echo $domen > /root/domain
    echo -e "${GB}[INFO]${NC} Standard domain setup: $domen"
    
elif test $dom -eq 2; then
    echo -e "${YB}[CLOUDFLARE SETUP]${NC}"
    echo -e "${YB}================================${NC}"
    echo -e "${YB}Before continue:${NC}"
    echo -e "1. Domain must be on Cloudflare"
    echo -e "2. DNS records must be DNS-only (no proxy)"
    echo -e "3. You need Cloudflare API Key"
    echo -e "${YB}================================${NC}"
    echo ""
    
    read -rp "Enter Your Main Domain (example.com): " main_domain
    echo "*.$main_domain" > /root/domain
    echo "MAIN_DOMAIN=$main_domain" > /root/cloudflare.conf
    
    # Cloudflare API Setup
    echo -e "${YB}[CLOUDFLARE API SETUP]${NC}"
    read -p "Cloudflare Email: " cf_email
    read -p "Cloudflare Global API Key: " cf_api_key
    
    # Validate Cloudflare credentials
    echo -e "${YB}[VALIDATING CLOUDFLARE CREDENTIALS]${NC}"
    response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$main_domain" \
        -H "X-Auth-Email: $cf_email" \
        -H "X-Auth-Key: $cf_api_key" \
        -H "Content-Type: application/json")
    
    if echo "$response" | grep -q '"success":true'; then
        echo -e "${GB}[SUCCESS]${NC} Cloudflare credentials validated!"
        zone_id=$(echo "$response" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
        echo "ZONE_ID=$zone_id" >> /root/cloudflare.conf
    else
        echo -e "${RB}[ERROR]${NC} Invalid Cloudflare credentials or domain not found in account!"
        echo -e "${YB}[INFO]${NC} Please check:"
        echo -e "1. Domain is in Cloudflare account"
        echo -e "2. API Key is correct"
        echo -e "3. Email is correct"
        exit 1
    fi
    
    # Save Cloudflare credentials
    mkdir -p /root/.secrets
    cat > /root/.secrets/cloudflare.ini << EOF
# Cloudflare API credentials
dns_cloudflare_email = $cf_email
dns_cloudflare_api_key = $cf_api_key
EOF
    chmod 600 /root/.secrets/cloudflare.ini
    
    # Install Certbot & Cloudflare plugin
    echo -e "${YB}[INSTALLING CERTBOT & CLOUDFLARE PLUGIN]${NC}"
    apt update
    apt install -y certbot python3-pip
    pip3 install certbot-dns-cloudflare
    
    # Obtain Wildcard Certificate
    echo -e "${YB}[OBTAINING WILDCARD CERTIFICATE]${NC}"
    certbot certonly \
        --dns-cloudflare \
        --dns-cloudflare-credentials /root/.secrets/cloudflare.ini \
        --dns-cloudflare-propagation-seconds 30 \
        -d "*.$main_domain" \
        -d "$main_domain" \
        --non-interactive \
        --agree-tos \
        --email admin@$main_domain
    
    if [ $? -eq 0 ]; then
        echo -e "${GB}[SUCCESS]${NC} Wildcard certificate obtained!"
        
        # Copy certificates for Xray
        mkdir -p /usr/local/etc/xray
        cp /etc/letsencrypt/live/$main_domain/fullchain.pem /usr/local/etc/xray/xray.crt
        cp /etc/letsencrypt/live/$main_domain/privkey.pem /usr/local/etc/xray/xray.key
        chmod 644 /usr/local/etc/xray/xray.crt
        chmod 600 /usr/local/etc/xray/xray.key
        
        # Setup auto-renewal
        (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet && systemctl reload nginx") | crontab -
        echo -e "${GB}[SUCCESS]${NC} Auto-renewal configured!"
    else
        echo -e "${RB}[ERROR]${NC} Failed to get wildcard certificate!"
        echo -e "${YB}[INFO]${NC} Falling back to standard certificate..."
        curl https://get.acme.sh | sh
        ~/.acme.sh/acme.sh --upgrade --auto-upgrade
        ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
        ~/.acme.sh/acme.sh --issue -d $main_domain --standalone -k ec-256
        ~/.acme.sh/acme.sh --installcert -d $main_domain --fullchainpath /usr/local/etc/xray/xray.crt --keypath /usr/local/etc/xray/xray.key --ecc
    fi

else 
    echo "Invalid option"
    exit 1
fi

echo -e "${GREEN}Domain setup completed!${NC}"
sleep 2
clear

# Continue with installation
echo "IP=$MYIP" >> /var/lib/premium-script/ipvps.conf
echo "IP=$MYIP" >> /var/lib/crot-script/ipvps.conf
domain=$(cat /root/domain)

# Install SSH-VPN
echo -e "\e[0;32mINSTALLING SSH-VPN...\e[0m"
sleep 1
wget -q -O /root/ssh-vpn2.sh "https://raw.githubusercontent.com/putrapetirr0/tuman/refs/heads/main/ssh-vpn2.sh"
chmod +x /root/ssh-vpn2.sh
./ssh-vpn2.sh
sleep 3
clear

# Install XRAY Core
echo -e "\e[0;32mINSTALLING XRAY CORE...\e[0m"
sleep 3
wget -q -O /root/xray-cloudflare.sh "https://raw.githubusercontent.com/putrapetirr0/tuman/refs/heads/main/xray-cloudflare.sh"
chmod +x /root/xray-cloudflare.sh
./xray-cloudflare.sh
echo -e "${GREEN}Done!${NC}"
sleep 2
clear

# Install SET-BR
echo -e "\e[0;32mINSTALLING SET-BR...\e[0m"
sleep 1
wget -q -O /root/set-br.sh "https://raw.githubusercontent.com/putrapetirr0/tuman/refs/heads/main/set-br.sh"
chmod +x /root/set-br.sh
./set-br.sh
echo -e "${GREEN}Done!${NC}"
sleep 2
clear

# Cleanup
rm -f /root/xray-cloudflare.sh /root/set-br.sh /root/ssh-vpn2.sh
echo "2.0" > /home/ver

# Completion message
clear
echo ""
echo -e "${RB}      .-------------------------------------------.${NC}"
echo -e "${RB}      |${NC}    ${CB}CLOUDFLARE INSTALL COMPLETED${NC}     ${RB}|${NC}"
echo -e "${RB}      '-------------------------------------------'${NC}"
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "      ${WB}Multiport Websocket + Cloudflare Wildcard${NC}"
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "  ${GB}✓${NC} ${WB}Domain:${NC} $domain"
if test $dom -eq 2; then
    echo -e "  ${GB}✓${NC} ${WB}Wildcard:${NC} Enabled (*.$main_domain)"
    echo -e "  ${GB}✓${NC} ${WB}Cloudflare:${NC} Integrated"
    echo -e "  ${GB}✓${NC} ${WB}Auto-renewal:${NC} Configured"
fi
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo ""
secs_to_human "$(($(date +%s) - ${start}))"
echo ""
rm -f setup2-cloudflare.sh
echo ""
read -p "$( echo -e "Press ${orange}[ ${NC}${green}Enter${NC} ${CYAN}]${NC} For Reboot") "
reboot
