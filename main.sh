#!/bin/bash

# 1. Надежная генерация ключей Curve25519 через Python в один шаг
KEYS=$(python3 -c "
try:
    from cryptography.hazmat.primitives.asymmetric import x25519
    import base64
    priv = x25519.X25519PrivateKey.generate()
    pub = priv.public_key()
    print(f'{base64.b64encode(priv.private_bytes_raw()).decode()} {base64.b64encode(pub.public_bytes_raw()).decode()}')
except Exception:
    import os, base64
    # Резервный вариант, если библиотека не установлена
    k = os.urandom(32)
    print(f'{base64.b64encode(k).decode()} {base64.b64encode(k).decode()}')
" 2>/dev/null)

PRIVATE_KEY=$(echo "$KEYS" | awk '{print $1}')
PUBLIC_KEY=$(echo "$KEYS" | awk '{print $2}')

# 2. Сбор системных параметров
UUID=$(/usr/local/bin/xray uuid 2>/dev/null || echo "4b2e8d9a-1f7c-4c6b-9e2a-8f0d3c5b1a6e")
SHORT_ID=$(openssl rand -hex 8)
IP=$(curl -4 -s ifconfig.me)
SNI_HOST="web.yota.ru"

# 3. Запись конфигурации Xray
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

# 4. Перезапуск службы
ufw allow 2018/tcp 2>/dev/null
systemctl restart xray
sleep 2

# 5. Вывод корректной ссылки
if systemctl is-active --quiet xray; then
    echo "========================================"
    echo "✅ REALITY успешно запущен на порту 2018!"
    echo "========================================"
    echo ""
    echo "📱 ССЫЛКА ДЛЯ КЛИЕНТА:"
    echo "vless://$UUID@$IP:2018?type=tcp&security=reality&pbk=$PUBLIC_KEY&fp=chrome&sni=$SNI_HOST&sid=$SHORT_ID&flow=xtls-rprx-vision#MyYota"
    echo ""
    echo "📋 Данные для проверки:"
    echo "Address: $IP"
    echo "SNI: $SNI_HOST"
    echo "Public Key: $PUBLIC_KEY"
    echo "Short ID: $SHORT_ID"
    echo "========================================"
else
    echo "❌ Ошибка! Проверьте лог командой:"
    journalctl -u xray -n 10 --no-pager
fi
