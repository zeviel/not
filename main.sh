cat << 'EOF' > fix_tg_proxy_v3.sh
#!/bin/bash

CONFIG_FILE="/etc/mtg-proxy/config.toml"
IMAGE_NAME="ghcr.io/mhasanei/mtg-multi:latest"
TAG="b62807b66282914bcbd6ef432b20b89f4"
IP_PUBLIC="185.229.66.115"
NEW_SECRET="eec741a811908c5b4238dee60fc14c784c7765622e796f74612e7275"

cat << CONF > $CONFIG_FILE
secret = "${NEW_SECRET}"
bind-to = "0.0.0.0:8443"
ad-tag = "${TAG}"
public-ipv4 = "${IP_PUBLIC}"
CONF

echo "Новая конфигурация записана!"
echo "Ваш НОВЫЙ секрет: ${NEW_SECRET}"

echo "=== 2. Перезапуск контейнера ==="
docker stop tg-proxy && docker rm tg-proxy 2>/dev/null

# Запускаем без флага --add-host, так как google.com резолвится штатно
docker run -d \
  --name tg-proxy \
  --restart=always \
  -p 8443:8443 \
  -v "/etc/mtg-proxy/:/config:ro" \
  $IMAGE_NAME run /config/config.toml

echo "=== 3. Проверка логов ==="
sleep 2
docker logs -f tg-proxy
EOF

chmod +x fix_tg_proxy_v3.sh && ./fix_tg_proxy_v3.sh
