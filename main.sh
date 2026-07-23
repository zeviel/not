bash <(curl -s https://raw.githubusercontent.com/XTLS/Xray-install/raw/main/install-release.sh) @ install -y && \
SERVER_IP=$(curl -4 -s ifconfig.me) && \
read -p "SNI (web.yota.ru): " SNI && SNI=${SNI:-web.yota.ru} && \
read -p "Port (2018): " PORT && PORT=${PORT:-2018} && \
KEY=$(/usr/local/bin/xray x25519) && \
PK=$(echo "$KEY" | grep Private | awk '{print $3}') && \
PB=$(echo "$KEY" | grep Public | awk '{print $3}') && \
UUID=$(/usr/local/bin/xray uuid) && \
SID=$(openssl rand -hex 8) && \
cat > /usr/local/etc/xray/config.json <<JSON
{"log":{"loglevel":"warning"},"inbounds":[{"port":$PORT,"protocol":"vless","settings":{"clients":[{"id":"$UUID","flow":"xtls-rprx-vision","email":"user1"}],"decryption":"none"},"streamSettings":{"network":"tcp","security":"reality","realitySettings":{"dest":"$SNI:443","serverNames":["$SNI"],"privateKey":"$PK","shortIds":["$SID"],"settings":{"publicKey":"$PB","fingerprint":"chrome"}}},"sniffing":{"enabled":true,"destOverride":["http","tls"]}}],"outbounds":[{"protocol":"freedom","tag":"direct"},{"protocol":"blackhole","tag":"block"}]}
JSON
systemctl restart xray && \
echo "vless://$UUID@$SERVER_IP:$PORT?type=tcp&security=reality&pbk=$PB&fp=chrome&sni=$SNI&sid=$SID&flow=xtls-rprx-vision#MyReality"
