#!/bin/bash

echo "🔄 Генерирую ключи..."
KEY_OUTPUT=$(/usr/local/bin/xray x25519)
PRIVATE_KEY=$(echo "$KEY_OUTPUT" | grep "Private" | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep "Public" | awk '{print $3}')

echo "✅ Private Key: $PRIVATE_KEY"
echo "✅ Public Key:  $PUBLIC_KEY"

echo "📝 Создаю конфиг..."

cat > /usr/local/etc/xray/config.json <<EOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "port": 2018,
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "c4ba5684-4909-46b0-b0ce-40e848a17a4a", "flow": "xtls-rprx-vision", "email": "user1"}],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "dest": "web.yota.ru:443",
        "serverNames": ["web.yota.ru"],
        "privateKey": "$PRIVATE_KEY",
        "shortIds": ["77c6dc39379611b6"],
        "settings": {"publicKey": "$PUBLIC_KEY", "fingerprint": "chrome"}
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

echo "🔍 Проверяю конфиг..."
/usr/local/bin/xray -config /usr/local/etc/xray/config.json -test

if [ $? -eq 0 ]; then
    echo "✅ Конфиг верный!"
    echo "🚀 Запускаю Xray..."
    systemctl restart xray
    sleep 2
    
    if systemctl is-active --quiet xray; then
        echo "✅ Xray работает!"
        echo ""
        echo "========================================"
        echo "📱 ССЫЛКА ДЛЯ КЛИЕНТА:"
        echo "vless://c4ba5684-4909-46b0-b0ce-40e848a17a4a@185.229.66.115:2018?type=tcp&security=reality&pbk=$PUBLIC_KEY&fp=chrome&sni=web.yota.ru&sid=77c6dc39379611b6&flow=xtls-rprx-vision#MyReality"
        echo "========================================"
    else
        echo "❌ Xray не запустился. Логи:"
        journalctl -u xray -n 10 --no-pager
    fi
else
    echo "❌ Ошибка в конфиге!"
    echo "Показываю конфиг:"
    cat /usr/local/etc/xray/config.json
fi
