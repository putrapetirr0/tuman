#!/bin/bash
clear
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\\E[0;47;30m     AUTO SETUP CLOUDFLARE + XRAY     \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# Warna
green='\e[0;32m'
red='\e[1;31m'
yellow='\e[1;33m'
NC='\e[0m'

# Cek root
if [ "$EUID" -ne 0 ]; then
  echo -e "${red}❌ Jalankan sebagai root!${NC}"
  exit 1
fi

# Cek dependensi dasar
apt update -y >/dev/null 2>&1
apt install curl jq -y >/dev/null 2>&1

echo -e "${green}=== SETUP CLOUDFLARE API TOKEN ===${NC}"
read -p "Cloudflare Email (optional): " CF_EMAIL
read -p "Cloudflare API Token: " CF_API_TOKEN
read -p "Domain (contoh: example.com): " DOMAIN

if [[ -z "$CF_API_TOKEN" || -z "$DOMAIN" ]]; then
    echo -e "${red}❌ API Token dan Domain wajib diisi.${NC}"
    exit 1
fi

# Simpan kredensial
mkdir -p /root/cloudflare
cat > /root/cloudflare/credentials << EOF
CF_API_TOKEN="${CF_API_TOKEN}"
CF_EMAIL="${CF_EMAIL}"
DOMAIN="${DOMAIN}"
EOF
chmod 600 /root/cloudflare/credentials

# Buat environment untuk acme.sh
cat > /etc/profile.d/cloudflare.sh << 'EOF'
export CF_Token="$(grep '^CF_API_TOKEN=' /root/cloudflare/credentials | cut -d'=' -f2- | tr -d '"')"
export CF_Email="$(grep '^CF_EMAIL=' /root/cloudflare/credentials | cut -d'=' -f2- | tr -d '"' 2>/dev/null)"
EOF
chmod 644 /etc/profile.d/cloudflare.sh
source /etc/profile.d/cloudflare.sh

# Simpan domain
echo "$DOMAIN" > /root/domain

# Dapatkan IP VPS
SERVER_IP=$(wget -qO- ipv4.icanhazip.com || curl -s ipinfo.io/ip || curl -sS ifconfig.me)
echo -e "${green}✅ IP VPS terdeteksi: ${yellow}$SERVER_IP${NC}"

echo -e "${green}→ Menyiapkan DNS records di Cloudflare...${NC}"

# Ambil Zone ID
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}" \
     -H "Authorization: Bearer ${CF_API_TOKEN}" \
     -H "Content-Type: application/json" | jq -r '.result[0].id')

if [[ "$ZONE_ID" == "null" || -z "$ZONE_ID" ]]; then
    echo -e "${red}❌ Gagal mendapatkan Zone ID. Pastikan token memiliki izin Zone.Zone:Read dan Zone.DNS:Edit.${NC}"
    exit 1
fi

# Tambahkan DNS A record utama dan wildcard
for SUB in "@" "*" "vpn"; do
  echo -e "${yellow}Menambahkan record: ${SUB}.${DOMAIN}${NC}"
  curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
       -H "Authorization: Bearer ${CF_API_TOKEN}" \
       -H "Content-Type: application/json" \
       --data "{\"type\":\"A\",\"name\":\"${SUB}\",\"content\":\"${SERVER_IP}\",\"ttl\":120,\"proxied\":true}" >/dev/null
done

echo -e "${green}✅ Semua DNS record dibuat dan CDN (orange cloud) aktif.${NC}"

# Pastikan semua A record diset proxied=true
RECORDS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=A" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" | jq -r '.result[] | .id')

for rec in $RECORDS; do
    curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/$rec" \
         -H "Authorization: Bearer ${CF_API_TOKEN}" \
         -H "Content-Type: application/json" \
         --data '{"proxied":true}' >/dev/null
done

echo -e "${green}✅ CDN proxy aktif untuk semua A record domain.${NC}"

# Tambahkan Page Rule agar path websocket tidak dicache
echo -e "${green}→ Menambahkan Page Rules...${NC}"
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/pagerules" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data "{\"targets\":[{\"target\":\"url\",\"constraint\":{\"operator\":\"matches\",\"value\":\"*.$DOMAIN/*\"}}],\"actions\":[{\"id\":\"cache_level\",\"value\":\"Bypass\"},{\"id\":\"ssl\",\"value\":\"flexible\"}],\"status\":\"active\"}" >/dev/null

echo -e "${green}✅ Page Rules ditambahkan (Bypass cache untuk path websocket).${NC}"

# Pastikan acme.sh environment
if [ ! -d /root/.acme.sh ]; then
    curl https://get.acme.sh -o /root/.acme.sh/acme.sh
    chmod +x /root/.acme.sh/acme.sh
    /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
fi

echo -e "${green}✅ Cloudflare & domain siap.${NC}"

# --- Install services ---
Server_URL="raw.githubusercontent.com/putrapetirr0/tuman/refs/heads/main"

echo -e "\e[0;32mINSTALLING SSH-VPN...\e[0m"
wget -q https://${Server_URL}/ssh-vpn2.sh && chmod +x ssh-vpn2.sh && ./ssh-vpn2.sh && rm -f ssh-vpn2.sh

echo -e "\e[0;32mINSTALLING XRAY CORE...\e[0m"
wget -q -O /root/xray2.sh "https://${Server_URL}/xray2.sh"
chmod +x /root/xray2.sh && ./xray2.sh && rm -f /root/xray2.sh

echo -e "\e[0;32mINSTALLING SET-BR...\e[0m"
wget -q -O /root/set-br.sh "https://${Server_URL}/set-br.sh"
chmod +x /root/set-br.sh && ./set-br.sh && rm -f /root/set-br.sh

# --- Finishing info (seperti setup2.sh) ---
echo "1.0" > /home/ver
clear
echo -e "${red}      .-------------------------------------------.${NC}"
echo -e "${red}      |${NC}      ${purple}Installation Has Been Completed${NC}     ${red}|${NC}"
echo -e "${red}      '-------------------------------------------'${NC}"
echo -e "${blue}————————————————————————————————————————————————————————${NC}"
echo -e "      Multiport Websocket Autoscript By ArAz1308"
echo -e "${blue}————————————————————————————————————————————————————————${NC}"
echo -e "  ${yellow}»»» Protocol Service «««  |  »»» Network Protocol «««${NC}  "
echo -e "${blue}————————————————————————————————————————————————————————${NC}"
echo -e "  Vmess Websocket        |  Websocket (CDN) TLS"
echo -e "  Vless Websocket        |  Websocket (CDN) NTLS"
echo -e "  Trojan Websocket       |  TCP XTLS"
echo -e "  Trojan TCP XTLS        |  TCP TLS"
echo -e "  Trojan TCP             |"
echo -e "${blue}————————————————————————————————————————————————————————${NC}"
echo -e "  YAML XRAY VMESS WS"
echo -e "  YAML XRAY VLESS WS"
echo -e "  YAML XRAY TROJAN WS"
echo -e "  YAML XRAY TROJAN XTLS"
echo -e "  YAML XRAY TROJAN TCP"
echo -e "${blue}————————————————————————————————————————————————————————${NC}"
echo -e "Server Information:"
echo -e "  Timezone : Asia/Kuala_Lumpur (GMT +8)"
echo -e "  Fail2Ban : ON"
echo -e "  Dflate   : ON"
echo -e "  Iptables : ON"
echo -e "  Auto-Reboot : ON"
echo -e "  IPV6    : OFF"
echo -e "  Autoreboot : 06.00 GMT +8"
echo -e "  Backup & Restore VPS Data"
echo -e "  Automatic Delete Expired Account"
echo -e "  Bandwith Monitor"
echo -e "  RAM & CPU Monitor"
echo -e "  Check Login User"
echo -e "  Check Created Config"
echo -e "  Automatic Clear Log"
echo -e "  Media Checker"
echo -e "  DNS Changer"
echo -e "Network Port Service: HTTP : 80,8080,8880 | HTTPS : 443"
echo ""
secs_to_human "$(($(date +%s) - ${start}))"
echo ""
read -p "Tekan ENTER untuk reboot VPS..." enter
reboot
