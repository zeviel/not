#!/bin/bash

echo "🔄 Настройка VLESS Reality..."

# Проверяем, есть ли Xray
if ! command -v /usr/local/bin/xray &> /dev/null; then
    echo "❌ Xray не найден! Устанавливаю..."
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
fi

# Получаем IP
IP=$(curl -4 -s ifconfig.me)
if [ -z "$IP" ]; then
    IP=$(hostname -I | awk '{print $1}')
fi
echo "IP сервера: $IP"

# Генерируем ключи с проверкой
echo "🔑 Генерация ключей..."
KEY_OUTPUT=$(/usr/local/bin/xray x25519 2>&1)

# Проверяем, что ключи сгенерировались
if echo "$KEY_OUTPUT" | grep -q "Private key"; then
    PRIVATE_KEY=$(echo "$KEY_OUTPUT" | grep "Private key" | awk '{print $3}')
    PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep "Public key" | awk '{print $3}')
    echo "✅ Ключи сгенерированы успешно"
else
    echo "⚠️ Ошибка генерации ключей, использую запасные"
    PRIVATE_KEY="2Ms3C7xPqR9sT1uVwXyZ4aBcDeFgHiJkLmNoP6QrStU"
    PUBLIC_KEY="8wXyZ4aBcDeFgHiJkLmNoP6QrStUvWxYz1AbCdEfGhIj"
fi

# Генерируем UUID
UUID=$(/usr/local/bin/xray uuid 2>/dev/null)
if [ -z "$UUID" ]; then
    echo "⚠️ Ошибка генерации UUID, использую запасной"
    UUID="cbf4b9ca-dfa3-4d2c-bfc8-1bedcdf8a7c8"
fi

# Генерируем Short ID
SHORT_ID=$(openssl rand -hex 8 2>/dev/null)
if [ -z "$SHORT_ID" ]; then
    echo "⚠️ Ошибка генерации Short ID, использую запасной"
    SHORT_ID="4cbc75446fa59c2a"
fi

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

echo "✅ Конфиг создан"

# Открываем порт
echo "🔓 Открываю порт 2018..."
ufw allow 2018/tcp 2>/dev/null

# Останавливаем и запускаем Xray
echo "🚀 Запускаю Xray..."
systemctl stop xray 2>/dev/null
pkill -f xray 2>/dev/null
sleep 1
systemctl start xray 2>/dev/null
sleep 3

# Проверяем статус
if systemctl is-active --quiet xray; then
    echo "✅ Xray запущен успешно!"
else
    echo "❌ Xray не запустился. Проверяю логи..."
    journalctl -u xray -n 10 --no-pager
    echo ""
    echo "Пробую запустить вручную для проверки ошибок:"
    /usr/local/bin/xray -config /usr/local/etc/xray/config.json 2>&1 | head -20
    exit 1
fi

# Формируем ссылку
VLESS_LINK="vless://${UUID}@${IP}:2018?type=tcp&security=reality&pbk=${PUBLIC_KEY}&fp=chrome&sni=web.yota.ru&sid=${SHORT_ID}&flow=xtls-rprx-vision#MyReality"

echo ""
echo "========================================"
echo "✅ ГОТОВО!"
echo "========================================"
echo "📱 ССЫЛКА ДЛЯ ПОДКЛЮЧЕНИЯ:"
echo "${VLESS_LINK}"
echo "========================================"
echo ""
echo "📋 Данные:"
echo "IP: ${IP}"
echo "Port: 2018"
echo "UUID: ${UUID}"
echo "Public Key: ${PUBLIC_KEY}"
echo "Short ID: ${SHORT_ID}"
echo "SNI: web.yota.ru"
echo "========================================"

# Сохраняем
cat > /root/reality-info.txt <<EOF
========================================
VLESS REALITY
========================================
${VLESS_LINK}
========================================
IP: ${IP}
Port: 2018
UUID: ${UUID}
Public Key: ${PUBLIC_KEY}
Private Key: ${PRIVATE_KEY}
Short ID: ${SHORT_ID}
SNI: web.yota.ru
Flow: xtls-rprx-vision
Fingerprint: chrome
========================================
EOF

echo "💾 Данные сохранены в: /root/reality-info.txt"
