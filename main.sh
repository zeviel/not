#!/bin/bash

echo "🔄 Генерирую ключи..."
PK=$(/usr/local/bin/xray x25519 | grep Private | awk '{print $3}')
PB=$(/usr/local/bin/xray x25519 | grep Public | awk '{print $3}')
UUID=$(/usr/local/bin/xray uuid)
SID=$(openssl rand -hex 8)
IP=$(curl -4 -s ifconfig.me)

echo "📝 Создаю конфиг..."
cat > /usr/local/etc/xray/config.json <<EOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "port": 2018,
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "$UUID", "flow": "xtls-rprx-vision", "email": "user1"}],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "dest": "web.yota.ru:443",
        "serverNames": ["web.yota.ru"],
        "privateKey": "$PK",
        "shortIds": ["$SID"],
        "settings": {"publicKey": "$PB", "fingerprint": "chrome"}
      }
    },
    "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
  }],
  "outbounds": [
    {"protocol": "freedom", "tag": "direct"},
    {"protocol": "blackhole", "tag": "block"}
  ]
}
EOF

echo "🔓 Открываю порт 2018..."
ufw allow 2018/tcp 2>/dev/null

echo "🚀 Запускаю Xray..."
systemctl restart xray 2>/dev/null || systemctl start xray 2>/dev/null
sleep 2

echo ""
echo "========================================"
echo "✅ ГОТОВО!"
echo "========================================"
echo "📱 ССЫЛКА ДЛЯ КЛИЕНТА:"
echo "vless://$UUID@$IP:2018?type=tcp&security=reality&pbk=$PB&fp=chrome&sni=web.yota.ru&sid=$SID&flow=xtls-rprx-vision#MyReality"
echo "========================================"
echo ""
echo "📋 Данные:"
echo "IP: $IP"
echo "Port: 2018"
echo "UUID: $UUID"
echo "Public Key: $PB"
echo "Short ID: $SID"
echo "SNI: web.yota.ru"
echo "========================================"

# Сохраняем в файл
cat > /root/reality-info.txt <<EOF
========================================
VLESS REALITY
========================================
vless://$UUID@$IP:2018?type=tcp&security=reality&pbk=$PB&fp=chrome&sni=web.yota.ru&sid=$SID&flow=xtls-rprx-vision#MyReality
========================================
IP: $IP
Port: 2018
UUID: $UUID
Public Key: $PB
Short ID: $SID
SNI: web.yota.ru
========================================
EOF

echo "💾 Данные сохранены в: /root/reality-info.txt"
echo ""
echo "🔍 Проверка статуса:"
systemctl status xray --no-pager | head -5
