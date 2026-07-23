#!/bin/bash

echo "🔄 Генерирую ключи..."

# Генерируем ключи правильно
KEY_OUTPUT=$(/usr/local/bin/xray x25519)
PRIVATE_KEY=$(echo "$KEY_OUTPUT" | grep "Private key" | awk '{print $NF}')
PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep "Public key" | awk '{print $NF}')

# Проверяем, что ключи получились
if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then
    echo "❌ Ошибка генерации ключей!"
    exit 1
fi

# Генерируем UUID и Short ID
UUID=$(/usr/local/bin/xray uuid)
SHORT_ID=$(openssl rand -hex 8)

# Получаем IP
IP=$(curl -4 -s ifconfig.me)
if [ -z "$IP" ]; then
    IP=$(hostname -I | awk '{print $1}')
fi

echo "✅ Ключи сгенерированы"
echo "Private Key: $PRIVATE_KEY"
echo "Public Key: $PUBLIC_KEY"

echo "📝 Создаю конфиг..."

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
            "id": "$UUID",
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
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [
            "$SHORT_ID"
          ],
          "settings": {
            "publicKey": "$PUBLIC_KEY",
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

echo "🔓 Открываю порт 2018..."
ufw allow 2018/tcp 2>/dev/null

echo "🚀 Запускаю Xray..."
systemctl stop xray 2>/dev/null
systemctl start xray 2>/dev/null

sleep 2

# Проверяем статус
if systemctl is-active --quiet xray; then
    echo "✅ Xray работает!"
else
    echo "❌ Ошибка запуска. Логи:"
    journalctl -u xray -n 10 --no-pager
    echo ""
    echo "🔍 Проверяем конфиг на ошибки:"
    /usr/local/bin/xray -config /usr/local/etc/xray/config.json -test
    exit 1
fi

# Формируем правильную ссылку
VLESS_LINK="vless://$UUID@$IP:2018?type=tcp&security=reality&pbk=$PUBLIC_KEY&fp=chrome&sni=web.yota.ru&sid=$SHORT_ID&flow=xtls-rprx-vision#MyReality"

echo ""
echo "========================================"
echo "✅ ГОТОВО!"
echo "========================================"
echo "📱 ССЫЛКА ДЛЯ КЛИЕНТА:"
echo "$VLESS_LINK"
echo "========================================"
echo ""
echo "📋 Данные:"
echo "IP: $IP"
echo "Port: 2018"
echo "UUID: $UUID"
echo "Public Key: $PUBLIC_KEY"
echo "Short ID: $SHORT_ID"
echo "SNI: web.yota.ru"
echo "========================================"

# Сохраняем в файл
cat > /root/reality-info.txt <<EOF
========================================
VLESS REALITY
========================================
$VLESS_LINK
========================================
IP: $IP
Port: 2018
UUID: $UUID
Public Key: $PUBLIC_KEY
Short ID: $SHORT_ID
SNI: web.yota.ru
Flow: xtls-rprx-vision
Fingerprint: chrome
========================================
EOF

echo "💾 Данные сохранены в: /root/reality-info.txt"
