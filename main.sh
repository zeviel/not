KEY_OUTPUT=$(/usr/local/bin/xray x25519)
PRIVATE_KEY=$(echo "$KEY_OUTPUT" | grep "Private" | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep "Public" | awk '{print $3}')
UUID=$(/usr/local/bin/xray uuid)
SHORT_ID=$(openssl rand -hex 8)
IP=$(curl -4 -s ifconfig.me)

echo "========================================"
echo "✅ Public Key: $PUBLIC_KEY"
echo "========================================"

cat > /usr/local/etc/xray/config.json <<JSON
{"log":{"loglevel":"warning"},"inbounds":[{"port":2018,"protocol":"vless","settings":{"clients":[{"id":"$UUID","flow":"xtls-rprx-vision","email":"user1"}],"decryption":"none"},"streamSettings":{"network":"tcp","security":"reality","realitySettings":{"dest":"static-mon.yandex.net:443","serverNames":["static-mon.yandex.net"],"privateKey":"$PRIVATE_KEY","shortIds":["$SHORT_ID"],"settings":{"publicKey":"$PUBLIC_KEY","fingerprint":"chrome"}}},"sniffing":{"enabled":true,"destOverride":["http","tls"]}}],"outbounds":[{"protocol":"freedom","tag":"direct"},{"protocol":"blackhole","tag":"block"}]}
JSON

ufw allow 2018/tcp 2>/dev/null
systemctl restart xray
sleep 2

if systemctl is-active --quiet xray; then
    echo "✅ Xray работает на порту 2018!"
    echo ""
    echo "========================================"
    echo "📱 ССЫЛКА ДЛЯ КЛИЕНТА:"
    echo "vless://$UUID@$IP:2018?type=tcp&security=reality&pbk=$PUBLIC_KEY&fp=chrome&sni=static-mon.yandex.net&sid=$SHORT_ID&flow=xtls-rprx-vision#MyYandex"
    echo "========================================"
    echo ""
    echo "📋 Данные для ручного ввода:"
    echo "Address: $IP"
    echo "Port: 2018"
    echo "UUID: $UUID"
    echo "Public Key: $PUBLIC_KEY"
    echo "Short ID: $SHORT_ID"
    echo "SNI: static-mon.yandex.net"
    echo "========================================"
else
    echo "❌ Ошибка! Проверьте логи:"
    journalctl -u xray -n 10 --no-pager
fi
