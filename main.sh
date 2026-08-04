apt install curl mc htop nano
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
systemctl stop xray.service
cat << 'EOF' > /usr/local/etc/xray/config.json
{
  "log": {
    "loglevel": "info"
  },
  "routing": {
    "rules": [],
    "domainStrategy": "AsIs"
  },
  "inbounds": [
    {
      "port": 42639,
      "tag": "ss",
      "protocol": "shadowsocks",
      "settings": {
        "method": "2022-blake3-aes-128-gcm",
        "password": "yx6cNyG5bLvWV4WRxYM+Vw==",
        "network": "tcp,udp"
      }
    },
    {
      "port": 443,
      "protocol": "vless",
      "tag": "vless_tls",
      "settings": {
        "clients": [
          {
            "id": "453d2b29-7554-4b62-9221-91b595ca905c",
            "email": "user@server",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "web.yota.ru:443",
          "xver": 0,
          "serverNames": [
            "web.yota.ru"
          ],
          "privateKey": "uB2W-oybnA0-UA4b9ZUIpEjFrId-y8oj3ELkhD4i20A",
          "minClientVer": "",
          "maxClientVer": "",
          "maxTimeDiff": 0,
          "shortIds": [
            "9da744301887b94b"
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
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "block"
    }
  ]
}
EOF
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 443 -j DNAT --to-destination 178.177.13.233:443
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination 178.177.13.233:80
systemctl daemon-reload
systemctl enable xray.service
systemctl start xray.service
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
apt install -y iptables-persistent
