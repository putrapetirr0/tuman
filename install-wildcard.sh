#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}[INFO]${NC} Wildcard Certificate Installation"

# Check if domain file exists
if [ ! -f /root/domain ]; then
    echo -e "${RED}[ERROR]${NC} Domain file not found!"
    exit 1
fi

domain=$(cat /root/domain)

if [[ $domain != *"*"* ]]; then
    echo -e "${YELLOW}[INFO]${NC} Not a wildcard domain, skipping wildcard setup."
    exit 0
fi

main_domain=$(echo $domain | sed 's/\*\.//')
echo -e "${GREEN}[INFO]${NC} Setting up wildcard certificate for: $domain"
echo -e "${GREEN}[INFO]${NC} Main domain: $main_domain"

# Install certbot and DNS plugins
echo -e "${YELLOW}[INFO]${NC} Installing Certbot and DNS plugins..."
apt update
apt install -y certbot python3-pip

# Install Cloudflare DNS plugin
pip3 install certbot-dns-cloudflare

# Create Cloudflare credentials directory
mkdir -p /root/.secrets
chmod 700 /root/.secrets

# Setup Cloudflare API credentials
echo -e "${YELLOW}[INPUT]${NC} Please provide Cloudflare API credentials for wildcard certificate:"
read -p "Cloudflare Email: " cf_email
read -p "Cloudflare Global API Key: " cf_api_key

# Create Cloudflare config
cat > /root/.secrets/cloudflare.ini << EOF
# Cloudflare API credentials used by Certbot
dns_cloudflare_email = $cf_email
dns_cloudflare_api_key = $cf_api_key
EOF

chmod 600 /root/.secrets/cloudflare.ini

# Obtain wildcard certificate
echo -e "${YELLOW}[INFO]${NC} Obtaining wildcard certificate..."
certbot certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials /root/.secrets/cloudflare.ini \
    --dns-cloudflare-propagation-seconds 60 \
    -d "$domain" \
    -d "$main_domain" \
    --non-interactive \
    --agree-tos \
    --email admin@$main_domain

if [ $? -eq 0 ]; then
    echo -e "${GREEN}[SUCCESS]${NC} Wildcard certificate obtained successfully!"
    
    # Create certificate directory for xray
    mkdir -p /usr/local/etc/xray
    
    # Copy certificates
    cp /etc/letsencrypt/live/$main_domain/fullchain.pem /usr/local/etc/xray/xray.crt
    cp /etc/letsencrypt/live/$main_domain/privkey.pem /usr/local/etc/xray/xray.key
    
    # Set proper permissions
    chmod 644 /usr/local/etc/xray/xray.crt
    chmod 600 /usr/local/etc/xray/xray.key
    
    echo -e "${GREEN}[SUCCESS]${NC} Certificates copied to Xray directory"
else
    echo -e "${RED}[ERROR]${NC} Failed to obtain wildcard certificate!"
    echo -e "${YELLOW}[INFO]${NC} Falling back to standard certificate..."
    /root/.acme.sh/acme.sh --issue -d $main_domain --standalone -k ec-256
    ~/.acme.sh/acme.sh --installcert -d $main_domain --fullchainpath /usr/local/etc/xray/xray.crt --keypath /usr/local/etc/xray/xray.key --ecc
fi

# Setup auto-renewal
echo -e "${YELLOW}[INFO]${NC} Setting up auto-renewal..."
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -

echo -e "${GREEN}[SUCCESS]${NC} Wildcard certificate setup completed!"
