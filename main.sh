#!/bin/bash
IP=$(curl -4 -s ifconfig.me)
UUID="4b2e8d9a-1f7c-4c6b-9e2a-8f0d3c5b1a6e"

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
        "security": "none"
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
    }
  ]
}
JSON

systemctl restart xray
sleep 2

if systemctl is-active --quiet xray; then
    echo "========================================"
    echo "✅ Xray запущен успешно!"
    echo "========================================"
    echo "📱 ССЫЛКА ДЛЯ КЛИЕНТА:"
    echo "vless://$UUID@$IP:2018?type=tcp&encryption=none&flow=xtls-rprx-vision#VLESS_TCP"
    echo "========================================"
else
    echo "❌ Ошибка запуска. Выполните команду:"
    echo "/usr/local/bin/xray uuid"
fi
