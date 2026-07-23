#!/bin/bash

# Генерация ключей (исправлен awk на $4)
KEY_OUTPUT=$(/usr/local/bin/xray x25519)
PRIVATE_KEY=$(echo "$KEY_OUTPUT" | grep -i "Private" | awk '{print $4}')
PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep -i "Public" | awk '{print $4}')


# Генерация ID
UUID=$(/usr/local/bin/xray uuid)
SHORT_ID=$(openssl rand -hex 8)
IP=$(curl -4 -s ifconfig.me)

# Запись конфигурации (исправлена структура REALITY)
cat > /usr/local/etc/xray/config.json <<JSON
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
            "id": "$UUID",
            "flow": "xtls-rprx-vision",
            "email": "user1"
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
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [
            "$SHORT_ID"
          ],
          "settings": {
            "fingerprint": "chrome"
          }
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
JSON

# Настройка сети и перезапуск
ufw allow 2018/tcp 2>/dev/null
systemctl restart xray
sleep 2

# Проверка статуса и вывод
if systemctl is-active --quiet xray; then
    echo "========================================"
    echo "✅ Xray работает на порту 2018!"
    echo "========================================"
    echo ""
    echo "📱 ССЫЛКА ДЛЯ КЛИЕНТА:"
    echo "vless://$UUID@$IP:2018?type=tcp&security=reality&pbk=$PUBLIC_KEY&fp=chrome&sni=web.yota.ru&sid=$SHORT_ID&flow=xtls-rprx-vision#MyYota"
    echo ""
    echo "📋 Данные для ручного ввода:"
    echo "Address: $IP"
    echo "Port: 2018"
    echo "UUID: $UUID"
    echo "Public Key: $PUBLIC_KEY"
    echo "Short ID: $SHORT_ID"
    echo "SNI: web.yota.ru"
    echo "========================================"
else
    echo "❌ Ошибка! Проверьте логи:"
    journalctl -u xray -n 10 --no-pager
fi
