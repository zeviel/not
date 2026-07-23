#!/bin/bash

echo "🔄 Генерирую ключи..."
KEY_OUTPUT=$(/usr/local/bin/xray x25519)
PRIVATE_KEY=$(echo "$KEY_OUTPUT" | grep "Private" | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep "Public" | awk '{print $3}')

# Убираем возможные пробелы
PUBLIC_KEY=$(echo "$PUBLIC_KEY" | tr -d ' ')
PRIVATE_KEY=$(echo "$PRIVATE_KEY" | tr -d ' ')

echo "✅ Public Key: $PUBLIC_KEY"

if [[ "$PUBLIC_KEY" == *" "* ]]; then
    echo "❌ Public Key содержит пробел! Исправьте вручную."
    echo "Сгенерируйте ключи командой: /usr/local/bin/xray x25519"
    exit 1
fi

echo "📝 Обновляю конфиг..."

sed -i "s/\"privateKey\": \".*\"/\"privateKey\": \"$PRIVATE_KEY\"/" /usr/local/etc/xray/config.json
sed -i "s/\"publicKey\": \".*\"/\"publicKey\": \"$PUBLIC_KEY\"/" /usr/local/etc/xray/config.json

echo "🚀 Перезапускаю Xray..."
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
    echo "❌ Ошибка! Проверьте логи:"
    journalctl -u xray -n 10 --no-pager
fi
