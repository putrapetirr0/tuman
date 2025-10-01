#!/bin/bash
clear
red='\e[1;31m'
green='\e[0;32m'
NC='\e[0m'

echo -e "${green}=================================${NC}"
echo -e "${green}  WILDCARD DOMAIN + CLOUDFLARE  ${NC}"
echo -e "${green}=================================${NC}"

# Install dependencies untuk Ubuntu 22.04
apt update -y
apt install -y curl wget python3 python3-pip jq

# Install Cloudflare Python package
pip3 install cloudflare

# Get Cloudflare details
echo ""
read -p "Enter your Cloudflare Email: " CF_EMAIL
read -p "Enter your Cloudflare Global API Key: " CF_API_KEY
read -p "Enter your Domain (example.com): " DOMAIN

# Validate domain
if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo -e "${red}Invalid domain format!${NC}"
    exit 1
fi

# Get server IP
SERVER_IP=$(curl -sS ipv4.icanhazip.com)

# Get Zone ID
echo -e "${green}[INFO] Getting Zone ID...${NC}"
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
  -H "X-Auth-Email: $CF_EMAIL" \
  -H "X-Auth-Key: $CF_API_KEY" \
  -H "Content-Type: application/json" | jq -r '.result[0].id')

if [ "$ZONE_ID" = "null" ]; then
    echo -e "${red}Error: Could not get Zone ID${NC}"
    exit 1
fi

# Create DNS records
create_dns_record() {
    local type=$1
    local name=$2
    local content=$3
    
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
      -H "X-Auth-Email: $CF_EMAIL" \
      -H "X-Auth-Key: $CF_API_KEY" \
      -H "Content-Type: application/json" \
      --data "{\"type\":\"$type\",\"name\":\"$name\",\"content\":\"$content\",\"ttl\":3600,\"proxied\":false}" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${green}✓ Created $type record for $name${NC}"
    else
        echo -e "${red}✗ Failed to create $type record for $name${NC}"
    fi
}

# Create records
create_dns_record "A" "$DOMAIN" "$SERVER_IP"
create_dns_record "A" "*.$DOMAIN" "$SERVER_IP"
create_dns_record "A" "vpn.$DOMAIN" "$SERVER_IP"
create_dns_record "A" "ns.$DOMAIN" "$SERVER_IP"

# Save domain
echo "$DOMAIN" > /root/domain
echo "IP=$DOMAIN" >> /var/lib/premium-script/ipvps.conf
echo "IP=$DOMAIN" >> /var/lib/crot-script/ipvps.conf

# Install acme.sh untuk wildcard certificate
echo -e "${green}[INFO] Installing SSL Wildcard Certificate...${NC}"
cd /root
curl https://get.acme.sh | sh
source ~/.bashrc

# Set Cloudflare credentials
export CF_Email="$CF_EMAIL"
export CF_Key="$CF_API_KEY"

# Issue wildcard certificate
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
~/.acme.sh/acme.sh --register-account -m admin@$DOMAIN
~/.acme.sh/acme.sh --issue --dns dns_cf -d "$DOMAIN" -d "*.$DOMAIN"

# Install certificate
mkdir -p /usr/local/etc/xray
~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
    --key-file /usr/local/etc/xray/xray.key \
    --fullchain-file /usr/local/etc/xray/xray.crt

# Auto renew script
cat > /root/renew-wildcard.sh << EOF
#!/bin/bash
export CF_Email="$CF_EMAIL"
export CF_Key="$CF_API_KEY"
/root/.acme.sh/acme.sh --renew -d $DOMAIN -d *.$DOMAIN --dns dns_cf --force
systemctl restart nginx
systemctl restart xray@*
EOF

chmod +x /root/renew-wildcard.sh

# Add to crontab
(crontab -l 2>/dev/null; echo "0 0 1 * * /root/renew-wildcard.sh >/dev/null 2>&1") | crontab -

echo -e "${green}=================================${NC}"
echo -e "${green}   WILDCARD SETUP COMPLETED     ${NC}"
echo -e "${green}=================================${NC}"
echo -e "Domain: $DOMAIN"
echo -e "Wildcard: *.$DOMAIN"
echo -e "Server IP: $SERVER_IP"
echo -e "SSL Certificate: Installed"
echo -e "Auto-renew: Configured"
echo -e "${green}=================================${NC}"

sleep 3