#!/bin/bash
red='\e[1;31m'
green='\e[0;32m'
purple='\e[0;35m'
orange='\e[0;33m'
NC='\e[0m'
export Server_URL="raw.githubusercontent.com/putrapetirr0/tuman/refs/heads/main"

clear
dateFromServer=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
biji=`date +"%Y-%m-%d" -d "$dateFromServer"`
#########################
MYIP=$(wget -qO- ipv4.icanhazip.com);
MYIP=$(curl -s ipinfo.io/ip )
MYIP=$(curl -sS ipv4.icanhazip.com)
MYIP=$(curl -sS ifconfig.me )
clear
red='\e[1;31m'
green='\e[0;32m'
yell='\e[1;33m'
tyblue='\e[1;36m'
purple='\e[0;35m'
NC='\e[0m'
purple() { echo -e "\\033[35;1m${*}\\033[0m"; }
tyblue() { echo -e "\\033[36;1m${*}\\033[0m"; }
yellow() { echo -e "\\033[33;1m${*}\\033[0m"; }
green() { echo -e "\\033[32;1m${*}\\033[0m"; }
red() { echo -e "\\033[31;1m${*}\\033[0m"; }

red='\e[1;31m'
green='\e[0;32m'
NC='\e[0m'
green() { echo -e "\\033[32;1m${*}\\033[0m"; }
red() { echo -e "\\033[31;1m${*}\\033[0m"; }

echo -e ""
# === CLOUDFLARE API TOKEN SETUP ===
if [ -f "/etc/profile.d/cloudflare.sh" ]; then
    source /etc/profile.d/cloudflare.sh
else
    echo -e "${red}❌ Cloudflare environment not found. Jalankan setup2.sh dulu.${NC}"
    exit 1
fi

if [ -z "$CF_Token" ]; then
    echo -e "${red}❌ Cloudflare Token tidak ditemukan. Jalankan setup2.sh dulu.${NC}"
    exit 1
fi

DOMAIN=$(cat /root/domain 2>/dev/null)
if [ -z "$DOMAIN" ]; then
    echo -e "${red}❌ File /root/domain tidak ditemukan. Jalankan setup2.sh dulu.${NC}"
    exit 1
fi

apt install -y jq curl >/dev/null 2>&1
SERVER_IP=$(curl -s ipv4.icanhazip.com)

# Ambil Zone ID
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}" \
    -H "Authorization: Bearer ${CF_Token}" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

if [ -z "$ZONE_ID" ] || [ "$ZONE_ID" = "null" ]; then
    echo -e "${red}❌ Tidak bisa mendapatkan Zone ID. Pastikan API Token memiliki izin Zone.Zone:Read & Zone.DNS:Edit.${NC}"
    exit 1
fi

# Buat record A + aktifkan CDN
for SUB in "@" "*" "vpn"; do
  echo -e "${yell}→ Membuat DNS record: ${SUB}.${DOMAIN}${NC}"
  curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
       -H "Authorization: Bearer ${CF_Token}" \
       -H "Content-Type: application/json" \
       --data "{\"type\":\"A\",\"name\":\"${SUB}\",\"content\":\"${SERVER_IP}\",\"ttl\":120,\"proxied\":true}" >/dev/null
done

# Pastikan semua A record diset proxied:true
RECORDS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=A" \
    -H "Authorization: Bearer ${CF_Token}" \
    -H "Content-Type: application/json" | jq -r '.result[] | .id')

for rec in $RECORDS; do
  curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/$rec" \
       -H "Authorization: Bearer ${CF_Token}" \
       -H "Content-Type: application/json" \
       --data '{"proxied":true}' >/dev/null
done

echo -e "${green}✅ Cloudflare CDN aktif untuk semua A record domain ${DOMAIN}.${NC}"
echo
domain=$(cat /root/domain)
# Check if certificate already exists (for wildcard)
# === WILDCARD SSL via Cloudflare API Token ===
if [ ! -f "/usr/local/etc/xray/xray.crt" ]; then
    echo -e "[ ${green}INFO${NC} ] Menerbitkan sertifikat wildcard SSL..."

    if [ ! -f /root/.acme.sh/acme.sh ]; then
        mkdir -p /root/.acme.sh
        curl https://get.acme.sh -o /root/.acme.sh/acme.sh
        chmod +x /root/.acme.sh/acme.sh
    fi

    /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt

    env CF_Token="$CF_Token" /root/.acme.sh/acme.sh --issue --dns dns_cf -d "$domain" -d "*.$domain" -k ec-256 --force

    if [ $? -eq 0 ]; then
        /root/.acme.sh/acme.sh --installcert -d "$domain" -d "*.$domain" \
            --fullchainpath /usr/local/etc/xray/xray.crt \
            --keypath /usr/local/etc/xray/xray.key --ecc \
            --reloadcmd "systemctl reload xray || true"
        echo -e "[ ${green}INFO${NC} ] Sertifikat wildcard berhasil diterbitkan & diinstal."
    else
        echo -e "[ ${red}ERROR${NC} ] Gagal menerbitkan sertifikat wildcard."
        exit 1
    fi
else
    echo -e "[ ${green}INFO${NC} ] Menggunakan sertifikat SSL yang sudah ada."
fi
sleep 1
echo -e "[ ${green}INFO${NC} ] XRAY Core Installation Begin . . . "
apt update -y
apt upgrade -y
apt install socat -y
apt install python -y
apt install curl -y
apt install wget -y
apt install sed -y
apt install nano -y
apt install python3 -y
apt install curl socat xz-utils wget apt-transport-https gnupg gnupg2 gnupg1 dnsutils lsb-release -y 
apt install socat cron bash-completion ntpdate -y
ntpdate pool.ntp.org
apt -y install chrony
timedatectl set-ntp true
systemctl enable chronyd && systemctl restart chronyd
systemctl enable chrony && systemctl restart chrony
timedatectl set-timezone Asia/Kuala_Lumpur
chronyc sourcestats -v
chronyc tracking -v
date
apt install zip -y
apt install curl pwgen openssl netcat cron -y

# Make Folder Log XRAY
mkdir -p /var/log/xray
chmod +x /var/log/xray

# Make Folder XRAY
mkdir -p /usr/local/etc/xray

# Download XRAY Core Latest Link
#latest_version="$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"

# Installation Xray Core
#xraycore_link="https://github.com/NevermoreSSH/Xray-core/releases/download/v$latest_version/xray-linux-64.zip"

# Unzip Xray Linux 64
#cd `mktemp -d`
#curl -sL "$xraycore_link" -o xray.zip
#unzip -q xray.zip && rm -rf xray.zip
#mv xray /usr/local/bin/xray
#chmod +x /usr/local/bin/xray

#Download XRAY Core Dharak
wget -O /usr/local/bin/xray "https://raw.githubusercontent.com/putrapetirr0/tuman/refs/heads/main/xray.linux.64bit"
chmod +x /usr/local/bin/xray

# generate certificates
mkdir /root/.acme.sh
curl https://raw.githubusercontent.com/NevermoreSSH/yourpath/main/acme.sh -o /root/.acme.sh/acme.sh
chmod +x /root/.acme.sh/acme.sh
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /usr/local/etc/xray/xray.crt --keypath /usr/local/etc/xray/xray.key --ecc
sleep 1

# Nginx directory file download
mkdir -p /home/vps/public_html

# set uuid
uuid=$(cat /proc/sys/kernel/random/uuid)

# // Installing VMESS-TLS
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
            "email": ""
#tls
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings":
            {
              "acceptProxyProtocol": true,
              "path": "/vmess-tls"
            }
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
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": [
      "StatsService"
    ],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true
    }
  }
}
END

# // INSTALLING VMESS NON-TLS
cat> /usr/local/etc/xray/none.json << END
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10085,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api"
    },
    {
     "listen": "127.0.0.1",
     "port": "23456",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "alterId": 0,
            "email": ""
#none
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
         },
        "quicSettings": {},
        "sockopt": {
          "mark": 0,
          "tcpFastOpen": true
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
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
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": [
      "StatsService"
    ],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true,
      "statsOutboundUplink" : true,
      "statsOutboundDownlink" : true
    }
  }
}
END

# // INSTALLING VLESS-TLS
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
            "email": ""
#tls
          }
        ],
        "decryption": "none"
      },
	  "encryption": "none",
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings":
            {
              "acceptProxyProtocol": true,
              "path": "/vless-tls"
            }
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
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": [
      "StatsService"
    ],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true
    }
  }
}
END

# // INSTALLING VLESS NON-TLS
cat> /usr/local/etc/xray/vnone.json << END
{
  "log": {
    "access": "/var/log/xray/access2.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10085,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api"
    },
    {
     "listen": "127.0.0.1",
     "port": "14016",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "level": 0,
            "email": ""
#none
          }
        ],
        "decryption": "none"
      },
      "encryption": "none",
      "streamSettings": {
        "network": "ws",
	"security": "none",
        "wsSettings": {
          "path": "/vless-ntls",
          "headers": {
            "Host": ""
          }
         },
        "quicSettings": {},
        "sockopt": {
          "mark": 0,
          "tcpFastOpen": true
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
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
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": [
      "StatsService"
    ],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true,
      "statsOutboundUplink" : true,
      "statsOutboundDownlink" : true
    }
  }
}
END

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
            "email": ""
#tr
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings":
            {
              "acceptProxyProtocol": true,
              "path": "/trojan-tls"
            }
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
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": [
      "StatsService"
    ],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true
    }
  }
}
END

# // INSTALLING TROJAN WS NONE TLS
cat > /usr/local/etc/xray/trnone.json << END
{
"log": {
        "access": "/var/log/xray/access3.log",
        "error": "/var/log/xray/error.log",
        "loglevel": "info"
    },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10085,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api"
    },
    {
      "listen": "127.0.0.1",
      "port": "25432",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "${uuid}",
            "level": 0,
            "email": ""
#trnone
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
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": [
      "StatsService"
    ],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true,
      "statsOutboundUplink" : true,
      "statsOutboundDownlink" : true
    }
  }
}
END

# // INSTALLING TROJAN TCP
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
                        "id": "${uuid}",
                        "password": "xxxxx"
#tr
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
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": [
      "StatsService"
    ],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true,
      "statsOutboundUplink" : true,
      "statsOutboundDownlink" : true
    }
  }
}
END

# // INSTALLING TROJAN TCP XTLS
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
            "id": "${uuid}",
            "flow": "xtls-rprx-direct",
            "level": 0,
            "email": ""
#trojan-xtls
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
		  "alpn": [
			"http/1.1",
			"h2"
		  ],
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
        "destOverride": [
          "http",
          "tls"
        ]
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

rm -rf /etc/systemd/system/xray.service.d
rm -rf /etc/systemd/system/xray@.service.d

cat> /etc/systemd/system/xray.service << END
[Unit]
Description=XRAY-Websocket Service
Documentation=https://NevermoreSSH-Project.net https://github.com/XTLS/Xray-core
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

cat> /etc/systemd/system/xray@.service << END
[Unit]
Description=XRAY-Websocket Service
Documentation=https://NevermoreSSH-Project.net https://github.com/XTLS/Xray-core
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

# ==========================================================
# === AUTO GENERATE NGINX CONFIG UNTUK SEMUA XRAY INBOUND ===
# ==========================================================
echo -e "[ ${green}INFO${NC} ] Membuat konfigurasi Nginx otomatis untuk Xray..."

# Lokasi cert SSL wildcard
CERT_PATH="/usr/local/etc/xray/xray.crt"
KEY_PATH="/usr/local/etc/xray/xray.key"

# Buat file Nginx baru
NGINX_CONF="/etc/nginx/conf.d/xray.conf"
cat > $NGINX_CONF <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain *.$domain;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $domain *.$domain;

    ssl_certificate $CERT_PATH;
    ssl_certificate_key $KEY_PATH;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:EECDH+AESGCM:EDH+AESGCM';
    ssl_prefer_server_ciphers on;

    root /usr/share/nginx/html;
    index index.html;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
EOF

# Loop semua file konfigurasi Xray untuk deteksi inbound
XRAY_DIR="/usr/local/etc/xray"
for file in $XRAY_DIR/*.json; do
    protocol=$(grep -m1 '"protocol"' "$file" | awk -F '"' '{print $4}')
    port=$(grep -m1 '"port"' "$file" | awk -F '"' '{print $4}')
    # Path biasanya terletak di wsSettings, jadi kita ambil jika ada
    path=$(grep -m1 '"path"' "$file" | awk -F '"' '{print $4}')

    # Nama pendek dari file, contoh: vless, vmess, trojan
    shortname=$(basename "$file" .json)

    # Jika tidak ada path, buat default berdasar nama file
    if [ -z "$path" ] || [ "$path" = "null" ]; then
        path="/${shortname}"
    fi

    echo -e "[ ${green}INFO${NC} ] Menambahkan route /${path} untuk $protocol ($shortname) port $port"

    # Tambahkan block proxy ke Nginx
    cat >> $NGINX_CONF <<NGINX
    location ${path} {
        proxy_pass http://127.0.0.1:${port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

NGINX
done

# Tutup blok server
cat >> $NGINX_CONF <<EOF
}
EOF

# Tes konfigurasi dan reload
nginx -t && systemctl reload nginx

if [ $? -eq 0 ]; then
    echo -e "[ ${green}OK${NC} ] Konfigurasi Nginx berhasil dibuat dan direload."
else
    echo -e "[ ${red}ERROR${NC} ] Gagal memuat konfigurasi Nginx, periksa /etc/nginx/conf.d/xray.conf"
fi

sleep 1
echo -e "[ ${orange}SERVICE${NC} ] Restart All service"
systemctl daemon-reload
sleep 1
echo -e "[ ${green}OK${NC} ] Enable & restart xray "

# enable xray vmess ws tls
echo -e "[ ${green}OK${NC} ] Restarting Vmess WS"
systemctl daemon-reload
systemctl enable xray.service
systemctl restart xray@*
systemctl restart xray.service

# enable xray vmess ws ntls
systemctl daemon-reload
systemctl enable xray.service
systemctl restart xray@*
systemctl restart xray.service

# enable xray vless ws tls
echo -e "[ ${green}OK${NC} ] Restarting Vless WS"
systemctl daemon-reload
systemctl enable xray.service
systemctl restart xray@*
systemctl restart xray.service

# enable xray vless ws ntls
systemctl daemon-reload
systemctl enable xray.service
systemctl restart xray@*
systemctl restart xray.service

# enable xray trojan ws tls
echo -e "[ ${green}OK${NC} ] Restarting Trojan WS"
systemctl daemon-reload
systemctl enable xray@trojanws.service
systemctl start xray@trojanws.service
systemctl restart xray@trojanws.service

# enable xray trojan ws ntls
systemctl daemon-reload
systemctl enable xray@trnone.service
systemctl start xray@trnone.service
systemctl restart xray@trnone.service

# enable xray trojan xtls
echo -e "[ ${green}OK${NC} ] Restarting Trojan XTLS"
systemctl daemon-reload
systemctl enable xray@xtrojan.service
systemctl start xray@xtrojan.service
systemctl restart xray@xtrojan.service

# enable xray trojan tcp
echo -e "[ ${green}OK${NC} ] Restarting Trojan TCP"
systemctl daemon-reload
systemctl enable xray@trojan.service
systemctl start xray@trojan.service
systemctl restart xray@trojan.service

# enable service multiport
echo -e "[ ${green}OK${NC} ] Restarting Multiport Service"
systemctl enable nginx
systemctl start nginx
systemctl restart nginx

# === AUTO RENEW WILDCARD SSL ===
if ! crontab -l 2>/dev/null | grep -q "acme.sh --cron"; then
    (crontab -l 2>/dev/null; echo "0 3 * * * /root/.acme.sh/acme.sh --cron --home /root/.acme.sh > /dev/null && systemctl reload xray") | crontab -
    echo -e "${green}✅ Cron job auto-renew SSL wildcard aktif.${NC}"
fi

sleep 1

cd /usr/bin
# // VMESS WS FILES
echo -e "[ ${green}INFO${NC} ] Downloading Vmess WS Files"
sleep 1
wget -O add-ws "https://${Server_URL}/add-ws.sh" && chmod +x add-ws
wget -O cek-ws "https://${Server_URL}/cek-ws.sh" && chmod +x cek-ws
wget -O del-ws "https://${Server_URL}/del-ws.sh" && chmod +x del-ws
wget -O renew-ws "https://${Server_URL}/renew-ws.sh" && chmod +x renew-ws
wget -O user-ws "https://${Server_URL}/user-ws.sh" && chmod +x user-ws
wget -O trial-ws "https://${Server_URL}/trial-ws.sh" && chmod +x trial-ws

# // VLESS WS FILES
echo -e "[ ${green}INFO${NC} ] Downloading Vless WS Files"
sleep 1
wget -O add-vless "https://${Server_URL}/add-vless.sh" && chmod +x add-vless
wget -O cek-vless "https://${Server_URL}/cek-vless.sh" && chmod +x cek-vless
wget -O del-vless "https://${Server_URL}/del-vless.sh" && chmod +x del-vless
wget -O renew-vless "https://${Server_URL}/renew-vless.sh" && chmod +x renew-vless
wget -O user-vless "https://${Server_URL}/user-vless.sh" && chmod +x user-vless
wget -O trial-vless "https://${Server_URL}/trial-vless.sh" && chmod +x trial-vless

# // TROJAN WS FILES
echo -e "[ ${green}INFO${NC} ] Downloading Trojan WS Files"
sleep 1
wget -O add-tr "https://${Server_URL}/add-tr.sh" && chmod +x add-tr
wget -O cek-tr "https://${Server_URL}/cek-tr.sh" && chmod +x cek-tr
wget -O del-tr "https://${Server_URL}/del-tr.sh" && chmod +x del-tr
wget -O renew-tr "https://${Server_URL}/renew-tr.sh" && chmod +x renew-tr
wget -O user-tr "https://${Server_URL}/user-tr.sh" && chmod +x user-tr
wget -O trial-tr "https://${Server_URL}/trial-tr.sh" && chmod +x trial-tr

# // TROJAN TCP XTLS
echo -e "[ ${green}INFO${NC} ] Downloading XRAY Vless TCP XTLS Files"
sleep 1
wget -O add-xrt "https://${Server_URL}/add-xrt.sh" && chmod +x add-xrt
wget -O cek-xrt "https://${Server_URL}/cek-xrt.sh" && chmod +x cek-xrt
wget -O del-xrt "https://${Server_URL}/del-xrt.sh" && chmod +x del-xrt
wget -O renew-xrt "https://${Server_URL}/renew-xrt.sh" && chmod +x renew-xrt
wget -O user-xrt "https://${Server_URL}/user-xrt.sh" && chmod +x user-xrt
wget -O trial-xrt "https://${Server_URL}/trial-xrt.sh" && chmod +x trial-xrt

# // TROJAN TCP FILES
echo -e "[ ${green}INFO${NC} ] Downloading Trojan TCP Files"
sleep 1
wget -O add-xtr "https://${Server_URL}/add-xtr.sh" && chmod +x add-xtr
wget -O cek-xtr "https://${Server_URL}/cek-xtr.sh" && chmod +x cek-xtr
wget -O del-xtr "https://${Server_URL}/del-xtr.sh" && chmod +x del-xtr
wget -O renew-xtr "https://${Server_URL}/renew-xtr.sh" && chmod +x renew-xtr
wget -O user-xtr "https://${Server_URL}/user-xtr.sh" && chmod +x user-xtr
wget -O trial-xtr "https://${Server_URL}/trial-xtr.sh" && chmod +x trial-xtr

# // OTHER FILES
echo -e "[ ${green}INFO${NC} ] Downloading Others Files"
sleep 1
rm -r xray2.sh
