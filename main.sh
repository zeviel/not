#!/bin/bash

# Динамически определяем только IP сервера
IP=$(curl -4 -s ifconfig.me)

# Запись конфигурации (все ключи жестко прописаны)
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
            "id": "4b2e8d9a-1f7c-4c6b-9e2a-8f0d3c5b1a6e",
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
          "privateKey": "uD8mK9vX6pQ4zF3tB1rE7wN2sX5c8v0b1n4m7k3j2hA=",
          "shortIds": [
            "e8f3b2a1c0d9e8f7"
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

# Проверка статуса и вывод (в ссылке и данных тоже прописаны статичные ключи)
if systemctl is-active --quiet xray; then
    echo "========================================"
    echo "✅ Xray успешно запущен на порту 2018!"
    echo "========================================"
    echo ""
    echo "📱 ССЫЛКА ДЛЯ КЛИЕНТА (Импортируйте в Nekobox/v2rayN/Shadowrocket):"
    echo "vless://4b2e8d9a-1f7c-4c6b-9e2a-8f0d3c5b1a6e@$IP:2018?type=tcp&security=reality&pbk=hR7wN2sX5c8v0b1n4m7k3j2hAuD8mK9vX6pQ4zF3tB0=&fp=chrome&sni=web.yota.ru&sid=e8f3b2a1c0d9e8f7&flow=xtls-rprx-vision#MyYota"
    echo ""
    echo "📋 Данные для ручного ввода:"
    echo "Address: $IP"
    echo "Port: 2018"
    echo "UUID: 4b2e8d9a-1f7c-4c6b-9e2a-8f0d3c5b1a6e"
    echo "Public Key: hR7wN2sX5c8v0b1n4m7k3j2hAuD8mK9vX6pQ4zF3tB0="
    echo "Short ID: e8f3b2a1c0d9e8f7"
    echo "SNI: web.yota.ru"
    echo "Flow: xtls-rprx-vision"
    echo "========================================"
else
    echo "❌ Ошибка! Проверьте логи командой:"
    echo "journalctl -u xray -n 10 --no-pager"
fi
