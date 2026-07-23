#!/bin/bash

echo "🔄 Генерирую ключи..."
KEY_OUTPUT=$(/usr/local/bin/xray x25519)

# Извлекаем ключи по ключевым словам (учитывая русский и английский варианты)
PRIVATE_KEY=$(echo "$KEY_OUTPUT" | grep -E -i "(private|закрытый)" | awk '{print $NF}')
PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep -E -i "(public|открытый)" | awk '{print $NF}')

echo "✅ Private Key: $PRIVATE_KEY"
echo "✅ Public Key:  $PUBLIC_KEY"

# Резервный метод извлечения, если grep не сработал
if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then
    echo "❌ Ошибка автоматического извлечения! Пробуем альтернативный метод..."
    PRIVATE_KEY=$(echo "$KEY_OUTPUT" | sed -n '1p' | awk '{print $NF}')
    PUBLIC_KEY=$(echo "$KEY_OUTPUT" | sed -n '2p' | awk '{print $NF}')
    
    if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then
        echo "❌ Ключи все еще пустые! Сгенерируйте вручную: /usr/local/bin/xray x25519"
        exit 1
    fi
fi

echo "📝 Создаю конфиг с портом 2018..."

rm -f /usr/local/etc/xray/config.json

cat > /usr/local/etc/xray/config.json <<EOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [
    {
      "port": 2018,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "c4ba5684-4909-46b0-b0ce-40e848a17a4a",
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
          "serverNames": ["web.yota.ru"],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": ["77c6dc39379611b6"],
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

echo "🔍 Проверяю конфиг..."
/usr/local/bin/xray -config /usr/local/etc/xray/config.json -test

if [ $? -eq 0 ]; then
    echo "✅ Конфиг верный!"
    echo "🚀 Перезапускаю сервис Xray..."
    systemctl restart xray 2>/dev/null || (pkill -f xray; /usr/local/bin/xray -config /usr/local/etc/xray/config.json &)
    sleep 3
    
    echo "========================================"
    echo "📱 ВАША ССЫЛКА ДЛЯ КЛИЕНТА (ПОРТ 2018):"
    echo "vless://c4ba5684-4909-46b0-b0ce-40e848a17a4a@185.229.66.115:2018?type=tcp&security=reality&pbk=$PUBLIC_KEY&fp=chrome&sni=web.yota.ru&sid=77c6dc39379611b6&flow=xtls-rprx-vision#BCS_Reality"
    echo "========================================"
    echo ""
    echo "📋 Данные также сохранены в: /root/reality-info.txt"
    cat > /root/reality-info.txt <<INFO
vless://c4ba5684-4909-46b0-b0ce-40e848a17a4a@185.229.66.115:2018?type=tcp&security=reality&pbk=$PUBLIC_KEY&fp=chrome&sni=web.yota.ru&sid=77c6dc39379611b6&flow=xtls-rprx-vision#BCS_Reality
INFO
else
    echo "❌ Ошибка в синтаксисе конфига!"
fi
