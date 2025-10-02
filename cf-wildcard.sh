#!/bin/bash
clear
red='\e[1;31m'
green='\e[0;32m'
NC='\e[0m'

echo -e "=========================================="
echo -e "    WILDCARD DOMAIN + CLOUDFLARE SETUP    "
echo -e "=========================================="

# Install dependencies untuk Ubuntu 22+
apt update -y
apt install -y curl wget python3 python3-pip jq

# Install Cloudflare CLI
pip3 install cloudflare

# Input Cloudflare credentials
echo -e "\n${green}➤ CLOUDFLARE CONFIGURATION${NC}"
read -p "Enter Cloudflare Email: " CF_EMAIL
read -p "Enter Cloudflare Global API Key: " CF_API_KEY
read -p "Enter your Domain (example.com): " DOMAIN

# Simpan credentials
mkdir -p /root/.cloudflare
echo "CF_EMAIL=$CF_EMAIL" > /root/.cloudflare/credentials
echo "CF_API_KEY=$CF_API_KEY" >> /root/.cloudflare/credentials
echo "DOMAIN=$DOMAIN" >> /root/.cloudflare/credentials
chmod 600 /root/.cloudflare/credentials

# Cek zone ID
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
    -H "X-Auth-Email: $CF_EMAIL" \
    -H "X-Auth-Key: $CF_API_KEY" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

if [ "$ZONE_ID" == "null" ]; then
    echo -e "${red}❌ Domain not found in Cloudflare${NC}"
    exit 1
fi

echo "ZONE_ID=$ZONE_ID" >> /root/.cloudflare/credentials

# Buat wildcard record
echo -e "\n${green}➤ CREATING WILDCARD RECORDS${NC}"

# Record untuk *.domain.com
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
    -H "X-Auth-Email: $CF_EMAIL" \
    -H "X-Auth-Key: $CF_API_KEY" \
    -H "Content-Type: application/json" \
    --data '{"type":"A","name":"*.'$DOMAIN'","content":"'$(curl -s ipv4.icanhazip.com)'","ttl":1,"proxied":true}' > /dev/null

# Record untuk domain.com (utama)
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
    -H "X-Auth-Email: $CF_EMAIL" \
    -H "X-Auth-Key: $CF_API_KEY" \
    -H "Content-Type: application/json" \
    --data '{"type":"A","name":"'$DOMAIN'","content":"'$(curl -s ipv4.icanhazip.com)'","ttl":1,"proxied":true}' > /dev/null

echo -e "${green}✅ Wildcard records created:${NC}"
echo -e "   • $DOMAIN"
echo -e "   • *.$DOMAIN"

# Generate wildcard certificate
echo -e "\n${green}➤ GENERATING WILDCARD SSL CERTIFICATE${NC}"
source /root/.cloudflare/credentials

# Install acme.sh dengan Cloudflare DNS challenge
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
~/.acme.sh/acme.sh --register-account -m $CF_EMAIL

# Export Cloudflare credentials untuk acme.sh
export CF_Email="$CF_EMAIL"
export CF_Key="$CF_API_KEY"

# Issue wildcard certificate
~/.acme.sh/acme.sh --issue --dns dns_cf -d "$DOMAIN" -d "*.$DOMAIN" --keylength ec-256

# Install certificate
mkdir -p /usr/local/etc/xray
~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
    --fullchain-file /usr/local/etc/xray/xray.crt \
    --key-file /usr/local/etc/xray/xray.key \
    --ecc

# Update domain file
echo "$DOMAIN" > /root/domain
echo "IP=$DOMAIN" > /var/lib/crot-script/ipvps.conf
echo "IP=$DOMAIN" > /var/lib/premium-script/ipvps.conf

echo -e "\n${green}✅ WILDCARD SETUP COMPLETED${NC}"
echo -e "Domain: $DOMAIN"
echo -e "Wildcard: *.$DOMAIN"
echo -e "SSL Certificate: Installed"

# Buat script renew certificate
cat > /root/renew-wildcard.sh << 'EOF'
#!/bin/bash
source /root/.cloudflare/credentials
export CF_Email="$CF_EMAIL"
export CF_Key="$CF_API_KEY"

~/.acme.sh/acme.sh --renew -d "$DOMAIN" -d "*.$DOMAIN" --ecc --force
systemctl restart nginx
systemctl restart xray@*
EOF

chmod +x /root/renew-wildcard.sh

# Add to crontab untuk auto renew
(crontab -l 2>/dev/null; echo "0 0 1 * * /root/renew-wildcard.sh") | crontab -

echo -e "\n${green}✅ Auto-renew scheduled in crontab${NC}"
