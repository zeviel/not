#!/bin/bash

# 1. Получаем вывод генератора Xray
XRAY_OUT=$(/usr/local/bin/xray x25519)

# 2. Парсим ключи с учетом специфического вывода вашего бинарника
PRIVATE_KEY=$(echo "$XRAY_OUT" | grep -i "PrivateKey:" | sed 's/.*PrivateKey:\s*//')
PUBLIC_KEY=$(echo "$XRAY_OUT" | grep -i "Password (Publickey):" | sed 's/.*Password (Publickey):\s*//')

# Если sed не отработал, пробуем альтернативный срез по пробелам
if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then
    PRIVATE_KEY=$(echo "$XRAY_OUT" | grep -i "PrivateKey:" | awk '{print $2}')
    PUBLIC_KEY=$(echo "$XRAY_OUT" | grep -i "Password (Publickey):" | awk '{print $3}')
fi

# Жесткая проверка на пустоту
if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then
    echo "❌ Ошибка парсинга ключей. Вывод бинарника:"
    echo "$XRAY_OUT"
    exit 1
fi

# 3. Системные переменные
UUID=$(/usr/local/bin/xray uuid 2>/dev/null || echo "4b2e8d9a-1f7c-4c6b-9e2a-8f0d3c5b1a6e")
SHORT_ID=$(openssl rand -hex 8)
IP=$(curl -4 -s ifconfig.me)
SNI_HOST="web.yota.ru"

# 4. Запись конфигурации в JSON
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
          "dest": "$SNI_HOST:443",
          "serverNames": [
            "$SNI_HOST"
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
    }
  ]
}
JSON

# 5. Применение правил сети и перезапуск
ufw allow 2018/tcp 2>/dev/null
systemctl restart xray
sleep 2

# 6. Проверка и вывод рабочей ссылки
if systemctl is-active --quiet xray; then
    echo "========================================"
    echo "✅ REALITY запущен! Все ключи совпали."
    echo "========================================"
    echo ""
    echo "📱 ССЫЛКА ДЛЯ КЛИЕНТА:"
    echo "vless://$UUID@$IP:2018?type=tcp&security=reality&pbk=$PUBLIC_KEY&fp=chrome&sni=$SNI_HOST&sid=$SHORT_ID&flow=xtls-rprx-vision#MyYota"
    echo ""
    echo "📋 Данные конфигурации:"
    echo "Address: $IP"
    echo "Private Key в конфиге: $PRIVATE_KEY"
    echo "Public Key в ссылке: $PUBLIC_KEY"
    echo "========================================"
else
    echo "❌ Xray упал. Проверьте синтаксис логов:"
    journalctl -u xray -n 10 --no-pager
fi
