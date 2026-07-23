#!/bin/bash

# 1. Получаем чистый вывод генератора Xray
XRAY_OUT=$(/usr/local/bin/xray x25519)

# 2. Надежно достаем ключи силами самого Bash (без awk)
if [[ $XRAY_OUT =~ Private\ key:\ +([A-Za-z0-9+/=]+) ]]; then
    PRIVATE_KEY="${BASH_REMATCH[1]}"
fi

if [[ $XRAY_OUT =~ Public\ key:\ +([A-Za-z0-9+/=]+) ]]; then
    PUBLIC_KEY="${BASH_REMATCH[1]}"
fi

# Проверка: если Xray не отдал ключи, выводим ошибку и стопаем
if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then
    echo "❌ Критическая ошибка: Не удалось получить ключи из Xray!"
    echo "Вывод команды был такой:"
    echo "$XRAY_OUT"
    exit 1
fi

# 3. Сбор остальных параметров
UUID=$(/usr/local/bin/xray uuid 2>/dev/null || echo "4b2e8d9a-1f7c-4c6b-9e2a-8f0d3c5b1a6e")
SHORT_ID=$(openssl rand -hex 8)
IP=$(curl -4 -s ifconfig.me)
SNI_HOST="web.yota.ru"

# 4. Запись конфигурации Xray
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

# 5. Перезапуск службы
ufw allow 2018/tcp 2>/dev/null
systemctl restart xray
sleep 2

# 6. Вывод корректной ссылки
if systemctl is-active --quiet xray; then
    echo "========================================"
    echo "✅ REALITY успешно запущен на порту 2018!"
    echo "========================================"
    echo ""
    echo "📱 ССЫЛКА ДЛЯ КЛИЕНТА (С ВАЛИДНЫМИ КЛЮЧАМИ):"
    echo "vless://$UUID@$IP:2018?type=tcp&security=reality&pbk=$PUBLIC_KEY&fp=chrome&sni=$SNI_HOST&sid=$SHORT_ID&flow=xtls-rprx-vision#MyYota"
    echo ""
    echo "📋 Данные для проверки:"
    echo "Address: $IP"
    echo "SNI: $SNI_HOST"
    echo "Public Key: $PUBLIC_KEY"
    echo "Short ID: $SHORT_ID"
    echo "========================================"
else
    echo "❌ Ошибка конфигурации! Проверьте лог:"
    journalctl -u xray -n 10 --no-pager
fi
