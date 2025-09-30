#!/bin/bash
red='\e[1;31m'
green='\e[0;32m'
yellow='\e[1;33m'
blue='\e[0;34m'
purple='\e[0;35m'
NC='\e[0m'
export Server_URL="raw.githubusercontent.com/putrapetirr0/tuman/refs/heads/main"

clear
dateFromServer=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
biji=`date +"%Y-%m-%d" -d "$dateFromServer"`

MYIP=$(curl -sS ipv4.icanhazip.com)
clear

# Color functions
purple() { echo -e "\\033[35;1m${*}\\033[0m"; }
blue() { echo -e "\\033[36;1m${*}\\033[0m"; }
yellow() { echo -e "\\033[33;1m${*}\\033[0m"; }
green() { echo -e "\\033[32;1m${*}\\033[0m"; }
red() { echo -e "\\033[31;1m${*}\\033[0m"; }

echo -e ""
domain=$(cat /root/domain)
sleep 1

# Check domain type
if [[ $domain == *"*"* ]]; then
    main_domain=$(echo $domain | sed 's/\*\.//')
    echo -e "[ ${green}INFO${NC} ] Wildcard Domain Detected: $domain"
    echo -e "[ ${green}INFO${NC} ] Main Domain: $main_domain"
    USE_WILDCARD=true
else
    main_domain=$domain
    USE_WILDCARD=false
    echo -e "[ ${green}INFO${NC} ] Standard Domain: $domain"
fi

echo -e "[ ${green}INFO${NC} ] XRAY Core with Cloudflare Installation Begin . . . "

# Install dependencies
echo -e "[ ${green}INFO${NC} ] Installing dependencies..."
apt update -y
apt upgrade -y
apt install -y socat python3 curl wget sed nano xz-utils gnupg gnupg2 gnupg1 \
               dnsutils lsb-release cron bash-completion ntpdate chrony \
               zip pwgen openssl netcat apt-transport-https

# Time setup
echo -e "[ ${green}INFO${NC} ] Configuring timezone..."
ntpdate pool.ntp.org
apt -y install chrony
timedatectl set-ntp true
systemctl enable chronyd && systemctl restart chronyd
systemctl enable chrony && systemctl restart chrony
timedatectl set-timezone Asia/Kuala_Lumpur
chronyc sourcestats -v
chronyc tracking -v
date

# Create directories
echo -e "[ ${green}INFO${NC} ] Creating directories..."
mkdir -p /var/log/xray
mkdir -p /usr/local/etc/xray
mkdir -p /home/vps/public_html
chmod +x /var/log/xray

# Download XRAY Core
echo -e "[ ${green}INFO${NC} ] Downloading Xray Core..."
wget -q -O /usr/local/bin/xray "https://raw.githubusercontent.com/putrapetirr0/tuman/refs/heads/main/xray.linux.64bit"
chmod +x /usr/local/bin/xray

# Certificate handling
echo -e "[ ${green}INFO${NC} ] Setting up SSL certificates..."

if [ "$USE_WILDCARD" = true ]; then
    echo -e "[ ${green}INFO${NC} ] Using Cloudflare wildcard certificate..."
    if [ -f "/etc/letsencrypt/live/$main_domain/fullchain.pem" ] && [ -f "/etc/letsencrypt/live/$main_domain/privkey.pem" ]; then
        echo -e "[ ${green}INFO${NC} ] Copying Let's Encrypt wildcard certificates..."
        cp /etc/letsencrypt/live/$main_domain/fullchain.pem /usr/local/etc/xray/xray.crt
        cp /etc/letsencrypt/live/$main_domain/privkey.pem /usr/local/etc/xray/xray.key
        chmod 644 /usr/local/etc/xray/xray.crt
        chmod 600 /usr/local/etc/xray/xray.key
        echo -e "[ ${green}SUCCESS${NC} ] Wildcard certificates configured!"
    else
        echo -e "[ ${yellow}WARNING${NC} ] Wildcard certificates not found, using fallback..."
        # Fallback to ACME.sh
        mkdir -p /root/.acme.sh
        curl -s https://get.acme.sh | sh > /dev/null 2>&1
        ~/.acme.sh/acme.sh --upgrade --auto-upgrade > /dev/null 2>&1
        ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt > /dev/null 2>&1
        ~/.acme.sh/acme.sh --issue -d $main_domain --standalone -k ec-256 > /dev/null 2>&1
        ~/.acme.sh/acme.sh --installcert -d $main_domain --fullchainpath /usr/local/etc/xray/xray.crt --keypath /usr/local/etc/xray/xray.key --ecc > /dev/null 2>&1
    fi
else
    # Standard certificate generation
    echo -e "[ ${green}INFO${NC} ] Generating standard SSL certificate..."
    mkdir -p /root/.acme.sh
    curl -s https://raw.githubusercontent.com/NevermoreSSH/yourpath/main/acme.sh -o /root/.acme.sh/acme.sh
    chmod +x /root/.acme.sh/acme.sh
    /root/.acme.sh/acme.sh --upgrade --auto-upgrade > /dev/null 2>&1
    /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt > /dev/null 2>&1
    /root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256 > /dev/null 2>&1
    ~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /usr/local/etc/xray/xray.crt --keypath /usr/local/etc/xray/xray.key --ecc > /dev/null 2>&1
fi

sleep 2

# Generate UUID
uuid=$(cat /proc/sys/kernel/random/uuid)
echo -e "[ ${green}INFO${NC} ] Generated UUID: $uuid"

# ==================================================
# XRAY CONFIGURATION FILES
# ==================================================

# VMESS WS TLS Configuration
echo -e "[ ${green}INFO${NC} ] Configuring VMESS WS TLS..."
cat> /usr/local/etc/xray/config.json << END
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
    {
      "port": 1311,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "alterId": 0,
            "level": 0,
            "email": "vmess-tls@${main_domain}"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/vmess-tls"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": ["0.0.0.0/8", "10.0.0.0/8", "100.64.0.0/10", "169.254.0.0/16", "172.16.0.0/12", "192.0.0.0/24", "192.0.2.0/24", "192.168.0.0/16", "198.18.0.0/15", "198.51.100.0/24", "203.0.113.0/24", "::1/128", "fc00::/7", "fe80::/10"],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": ["bittorrent"]
      }
    ]
  }
}
END

# VMESS WS NON-TLS Configuration
echo -e "[ ${green}INFO${NC} ] Configuring VMESS WS NON-TLS..."
cat> /usr/local/etc/xray/none.json << END
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
    {
      "port": 23456,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "alterId": 0,
            "level": 0,
            "email": "vmess-ntls@${main_domain}"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/vmess-ntls",
          "headers": {
            "Host": ""
          }
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": ["0.0.0.0/8", "10.0.0.0/8", "100.64.0.0/10", "169.254.0.0/16", "172.16.0.0/12", "192.0.0.0/24", "192.0.2.0/24", "192.168.0.0/16", "198.18.0.0/15", "198.51.100.0/24", "203.0.113.0/24", "::1/128", "fc00::/7", "fe80::/10"],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": ["bittorrent"]
      }
    ]
  }
}
END

# VLESS WS TLS Configuration
echo -e "[ ${green}INFO${NC} ] Configuring VLESS WS TLS..."
cat> /usr/local/etc/xray/vless.json << END
{
  "log": {
    "access": "/var/log/xray/access2.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
    {
      "port": 1312,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "level": 0,
            "email": "vless-tls@${main_domain}"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/vless-tls"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": ["0.0.0.0/8", "10.0.0.0/8", "100.64.0.0/10", "169.254.0.0/16", "172.16.0.0/12", "192.0.0.0/24", "192.0.2.0/24", "192.168.0.0/16", "198.18.0.0/15", "198.51.100.0/24", "203.0.113.0/24", "::1/128", "fc00::/7", "fe80::/10"],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": ["bittorrent"]
      }
    ]
  }
}
END

# VLESS WS NON-TLS Configuration
echo -e "[ ${green}INFO${NC} ] Configuring VLESS WS NON-TLS..."
cat> /usr/local/etc/xray/vnone.json << END
{
  "log": {
    "access": "/var/log/xray/access2.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
    {
      "port": 14016,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "level": 0,
            "email": "vless-ntls@${main_domain}"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/vless-ntls",
          "headers": {
            "Host": ""
          }
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": ["0.0.0.0/8", "10.0.0.0/8", "100.64.0.0/10", "169.254.0.0/16", "172.16.0.0/12", "192.0.0.0/24", "192.0.2.0/24", "192.168.0.0/16", "198.18.0.0/15", "198.51.100.0/24", "203.0.113.0/24", "::1/128", "fc00::/7", "fe80::/10"],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": ["bittorrent"]
      }
    ]
  }
}
END

# TROJAN WS TLS Configuration
echo -e "[ ${green}INFO${NC} ] Configuring TROJAN WS TLS..."
cat> /usr/local/etc/xray/trojanws.json << END
{
  "log": {
    "access": "/var/log/xray/access3.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
    {
      "port": 1313,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "${uuid}",
            "level": 0,
            "email": "trojan-tls@${main_domain}"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/trojan-tls"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": ["0.0.0.0/8", "10.0.0.0/8", "100.64.0.0/10", "169.254.0.0/16", "172.16.0.0/12", "192.0.0.0/24", "192.0.2.0/24", "192.168.0.0/16", "198.18.0.0/15", "198.51.100.0/24", "203.0.113.0/24", "::1/128", "fc00::/7", "fe80::/10"],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": ["bittorrent"]
      }
    ]
  }
}
END

# TROJAN WS NON-TLS Configuration
echo -e "[ ${green}INFO${NC} ] Configuring TROJAN WS NON-TLS..."
cat > /usr/local/etc/xray/trnone.json << END
{
  "log": {
    "access": "/var/log/xray/access3.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
    {
      "port": 25432,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "${uuid}",
            "level": 0,
            "email": "trojan-ntls@${main_domain}"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/trojan-ntls",
          "headers": {
            "Host": ""
          }
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": ["0.0.0.0/8", "10.0.0.0/8", "100.64.0.0/10", "169.254.0.0/16", "172.16.0.0/12", "192.0.0.0/24", "192.0.2.0/24", "192.168.0.0/16", "198.18.0.0/15", "198.51.100.0/24", "203.0.113.0/24", "::1/128", "fc00::/7", "fe80::/10"],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": ["bittorrent"]
      }
    ]
  }
}
END

# TROJAN TCP Configuration
echo -e "[ ${green}INFO${NC} ] Configuring TROJAN TCP..."
cat > /usr/local/etc/xray/trojan.json << END
{
  "log": {
    "access": "/var/log/xray/access4.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
    {
      "port": 1310,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "${uuid}",
            "level": 0,
            "email": "trojan-tcp@${main_domain}"
          }
        ],
        "fallbacks": [
          {
            "dest": 80
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {
          "acceptProxyProtocol": true
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": ["0.0.0.0/8", "10.0.0.0/8", "100.64.0.0/10", "169.254.0.0/16", "172.16.0.0/12", "192.0.0.0/24", "192.0.2.0/24", "192.168.0.0/16", "198.18.0.0/15", "198.51.100.0/24", "203.0.113.0/24", "::1/128", "fc00::/7", "fe80::/10"],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": ["bittorrent"]
      }
    ]
  }
}
END

# TROJAN XTLS Configuration (Main Entry Point)
echo -e "[ ${green}INFO${NC} ] Configuring TROJAN XTLS (Main Entry)..."
cat > /usr/local/etc/xray/xtrojan.json << END
{
  "log": {
    "access": "/var/log/xray/access5.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
    {
      "port": 443,
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "${uuid}",
            "flow": "xtls-rprx-direct",
            "level": 0,
            "email": "xtrojan@${main_domain}"
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "dest": 1310,
            "xver": 1
          },
          {
            "alpn": "h2",
            "dest": 1318,
            "xver": 1
          },
          {
            "path": "/vmess-tls",
            "dest": 1311,
            "xver": 1
          },
          {
            "path": "/vless-tls",
            "dest": 1312,
            "xver": 1
          },
          {
            "path": "/trojan-tls",
            "dest": 1313,
            "xver": 1
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "xtls",
        "xtlsSettings": {
          "minVersion": "1.2",
          "alpn": ["http/1.1", "h2"],
          "certificates": [
            {
              "certificateFile": "/usr/local/etc/xray/xray.crt",
              "keyFile": "/usr/local/etc/xray/xray.key"
            }
          ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
END

# ==================================================
# SYSTEMD SERVICE FILES
# ==================================================

echo -e "[ ${green}INFO${NC} ] Creating systemd services..."

# Remove old service directories
rm -rf /etc/systemd/system/xray.service.d
rm -rf /etc/systemd/system/xray@.service.d

# Main Xray service
cat> /etc/systemd/system/xray.service << END
[Unit]
Description=XRAY VMESS WS TLS Service
Documentation=https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartSec=3s
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
END

# Xray template service for multiple configurations
cat> /etc/systemd/system/xray@.service << END
[Unit]
Description=XRAY Service for %i
Documentation=https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/%i.json
Restart=on-failure
RestartSec=3s
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
END

# ==================================================
# NGINX CONFIGURATION
# ==================================================

echo -e "[ ${green}INFO${NC} ] Configuring Nginx..."

# Create nginx config for Xray
cat >/etc/nginx/conf.d/xray.conf <<EOF
server {
    listen 80;
    listen [::]:80;
    listen 8080;
    listen [::]:8080;
    listen 8880;
    listen [::]:8880;
    
    server_name $main_domain *.$main_domain;
    
    # SSL Configuration
    ssl_certificate /usr/local/etc/xray/xray.crt;
    ssl_certificate_key /usr/local/etc/xray/xray.key;
    ssl_ciphers EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5;
    ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
    
    root /home/vps/public_html;
    index index.html;
    
    # Cloudflare Real IP
    set_real_ip_from 103.21.244.0/22;
    set_real_ip_from 103.22.200.0/22;
    set_real_ip_from 103.31.4.0/22;
    set_real_ip_from 104.16.0.0/13;
    set_real_ip_from 104.24.0.0/14;
    set_real_ip_from 108.162.192.0/18;
    set_real_ip_from 131.0.72.0/22;
    set_real_ip_from 141.101.64.0/18;
    set_real_ip_from 162.158.0.0/15;
    set_real_ip_from 172.64.0.0/13;
    set_real_ip_from 173.245.48.0/20;
    set_real_ip_from 188.114.96.0/20;
    set_real_ip_from 190.93.240.0/20;
    set_real_ip_from 197.234.240.0/22;
    set_real_ip_from 198.41.128.0/17;
    real_ip_header CF-Connecting-IP;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # VLESS NON-TLS
    location = /vless-ntls {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:14016;
        proxy_http_version 1.1;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
    
    # VMESS NON-TLS
    location = /vmess-ntls {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:23456;
        proxy_http_version 1.1;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
    
    # TROJAN NON-TLS
    location = /trojan-ntls {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:25432;
        proxy_http_version 1.1;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
    
    # Block access to sensitive files
    location ~ /\.ht {
        deny all;
    }
    
    location ~* \.(log|conf|ini)$ {
        deny all;
    }
}
EOF

# Create default page
echo "<!DOCTYPE html>
<html>
<head>
    <title>Welcome to $main_domain</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        h1 { color: #333; }
        .info { background: #f4f4f4; padding: 20px; margin: 20px auto; max-width: 600px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Welcome to $main_domain</h1>
    <div class='info'>
        <p>Xray Server is running successfully!</p>
        <p>Domain: $main_domain</p>
        <p>Wildcard Support: $USE_WILDCARD</p>
        <p>Cloudflare Integrated: Yes</p>
    </div>
</body>
</html>" > /home/vps/public_html/index.html

# ==================================================
# START SERVICES
# ==================================================

echo -e "[ ${green}INFO${NC} ] Starting services..."

systemctl daemon-reload

# Start Xray services
services=("xray" "xray@none" "xray@vless" "xray@vnone" "xray@trojanws" "xray@trnone" "xray@trojan" "xray@xtrojan")

for service in "${services[@]}"; do
    systemctl enable $service > /dev/null 2>&1
    systemctl start $service > /dev/null 2>&1
    systemctl restart $service > /dev/null 2>&1
    echo -e "[ ${green}OK${NC} ] Service $service started"
done

# Start and enable Nginx
systemctl enable nginx > /dev/null 2>&1
systemctl start nginx > /dev/null 2>&1
systemctl restart nginx > /dev/null 2>&1
echo -e "[ ${green}OK${NC} ] Nginx started"

# ==================================================
# DOWNLOAD MANAGEMENT SCRIPTS
# ==================================================

echo -e "[ ${green}INFO${NC} ] Downloading management scripts..."

cd /usr/bin

# VMESS Management
wget -q -O add-ws "https://${Server_URL}/add-ws.sh" && chmod +x add-ws
wget -q -O cek-ws "https://${Server_URL}/cek-ws.sh" && chmod +x cek-ws
wget -q -O del-ws "https://${Server_URL}/del-ws.sh" && chmod +x del-ws
wget -q -O renew-ws "https://${Server_URL}/renew-ws.sh" && chmod +x renew-ws
wget -q -O trial-ws "https://${Server_URL}/trial-ws.sh" && chmod +x trial-ws

# VLESS Management
wget -q -O add-vless "https://${Server_URL}/add-vless.sh" && chmod +x add-vless
wget -q -O cek-vless "https://${Server_URL}/cek-vless.sh" && chmod +x cek-vless
wget -q -O del-vless "https://${Server_URL}/del-vless.sh" && chmod +x del-vless
wget -q -O renew-vless "https://${Server_URL}/renew-vless.sh" && chmod +x renew-vless
wget -q -O trial-vless "https://${Server_URL}/trial-vless.sh" && chmod +x trial-vless

# Trojan Management
wget -q -O add-tr "https://${Server_URL}/add-tr.sh" && chmod +x add-tr
wget -q -O cek-tr "https://${Server_URL}/cek-tr.sh" && chmod +x cek-tr
wget -q -O del-tr "https://${Server_URL}/del-tr.sh" && chmod +x del-tr
wget -q -O renew-tr "https://${Server_URL}/renew-tr.sh" && chmod +x renew-tr
wget -q -O trial-tr "https://${Server_URL}/trial-tr.sh" && chmod +x trial-tr

# XTLS Management
wget -q -O add-xrt "https://${Server_URL}/add-xrt.sh" && chmod +x add-xrt
wget -q -O cek-xrt "https://${Server_URL}/cek-xrt.sh" && chmod +x cek-xrt
wget -q -O del-xrt "https://${Server_URL}/del-xrt.sh" && chmod +x del-xrt
wget -q -O renew-xrt "https://${Server_URL}/renew-xrt.sh" && chmod +x renew-xrt
wget -q -O trial-xrt "https://${Server_URL}/trial-xrt.sh" && chmod +x trial-xrt

echo -e "[ ${green}SUCCESS${NC} ] All management scripts downloaded"

# ==================================================
# FINALIZATION
# ==================================================

sleep 2
echo -e ""
echo -e "${blue}============================================${NC}"
echo -e "${green}   XRAY CORE WITH CLOUDFLARE INSTALLED    ${NC}"
echo -e "${blue}============================================${NC}"
echo -e "${yellow}Domain:${NC} $domain"
echo -e "${yellow}Main Domain:${NC} $main_domain"
echo -e "${yellow}Wildcard Support:${NC} $USE_WILDCARD"
echo -e "${yellow}UUID:${NC} $uuid"
echo -e "${blue}============================================${NC}"
echo -e "${green}Services Status:${NC}"
echo -e "Xray Core: ${green}Running${NC}"
echo -e "Nginx: ${green}Running${NC}"
echo -e "Cloudflare: ${green}Integrated${NC}"
echo -e "${blue}============================================${NC}"
echo -e ""

# Cleanup
rm -f /root/xray-cloudflare.sh

echo -e "[ ${green}SUCCESS${NC} ] Installation completed successfully!"
echo -e "[ ${green}INFO${NC} ] You can now use management scripts: add-ws, add-vless, add-tr"
