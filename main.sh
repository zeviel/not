#!/bin/bash

echo "🔧 Генерация новых ключей..."

systemctl stop xray 2>/dev/null

KEY_OUTPUT=$(/usr/local/bin/xray x25519 2>&1)
PRIVATE_KEY=$(echo "$KEY_OUTPUT" | grep -i "private" | sed 's/.*://' | tr -d ' -_=' | sed 's/[^A-Za-z0-9]//g')
PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep -i "public" | sed 's/.*://' | tr -d ' -_=' | sed 's/[^A-Za-z0-9]//g')

if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then
    echo "❌ Ошибка генерации ключей!"
    exit 1
fi

echo "✅ Private Key: $PRIVATE_KEY"
echo "✅ Public Key: $PUBLIC_KEY"

UUID=$(/usr/local/bin/xray uuid)
SHORT_ID=$(openssl rand -hex 8)
IP=$(curl -4 -s ifconfig.me)

cat > /usr/local/etc/xray/config.json <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 2018,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${UUID}",
            "flow": "xtls-rprx-vision",
            "email": "user1@example.com"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "web.yota.ru:443",
          "serverNames": [
            "web.yota.ru"
          ],
          "privateKey": "${PRIVATE_KEY}",
          "shortIds": [
            "${SHORT_ID}"
          ],
          "settings": {
            "publicKey": "${PUBLIC_KEY}",
            "fingerprint": "chrome"
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
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "block"
    }
  ]
}
EOF

echo "🔍 Проверяем конфиг..."
/usr/local/bin/xray -config /usr/local/etc/xray/config.json -test

if [ $? -ne 0 ]; then
    echo "❌ Ошибка в конфиге!"
    exit 1
fi

systemctl start xray
sleep 2

if systemctl is-active --quiet xray; then
    echo "✅ Xray успешно запущен!"
    echo ""
    echo "========================================"
    echo "📱 ССЫЛКА ДЛЯ КЛИЕНТА:"
    echo "vless://${UUID}@${IP}:2018?type=tcp&security=reality&pbk=${PUBLIC_KEY}&fp=chrome&sni=web.yota.ru&sid=${SHORT_ID}&flow=xtls-rprx-vision#MyYota"
    echo "========================================"
    echo ""
    echo "📋 Данные для ручного ввода:"
    echo "Address: ${IP}"
    echo "Port: 2018"
    echo "UUID: ${UUID}"
    echo "Public Key: ${PUBLIC_KEY}"
    echo "Short ID: ${SHORT_ID}"
    echo "SNI: web.yota.ru"
    echo "========================================"
    
    cat > /root/reality-info.txt <<EOF2
========================================
VLESS REALITY - web.yota.ru
========================================
vless://${UUID}@${IP}:2018?type=tcp&security=reality&pbk=${PUBLIC_KEY}&fp=chrome&sni=web.yota.ru&sid=${SHORT_ID}&flow=xtls-rprx-vision#MyYota
========================================
IP: ${IP}
Port: 2018
UUID: ${UUID}
Public Key: ${PUBLIC_KEY}
Private Key: ${PRIVATE_KEY}
Short ID: ${SHORT_ID}
SNI: web.yota.ru
========================================
EOF2
    echo "💾 Данные сохранены в: /root/reality-info.txt"
else
    echo "❌ Xray не запустился. Логи:"
    journalctl -u xray -n 10 --no-pager
fi
