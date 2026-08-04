# Останавливаем и удаляем старый, падающий
docker stop tg-proxy && docker rm -f tg-proxy

# Удаляем старую папку с данными, чтобы начать с нуля
rm -rf ~/mtproxy_data && mkdir -p ~/mtproxy_data

# Даём полные права на папку (777) на хосте, чтобы контейнер точно мог в неё писать
chmod 777 ~/mtproxy_data

# Создаём docker-compose.yml прямо в текущей папке
cat > docker-compose.yml << 'EOF'
version: '3'
services:
  tg-proxy:
    image: seriyps/mtproto-proxy:latest
    container_name: tg-proxy
    restart: always
    ports:
      - "8443:443"
    environment:
      - SECRET=c741a811908c5b4238dee60fc14c784c
      - TAG=b62807b6682914bcbde6f432b20b89f4
      - TLS_DOMAIN=web.yota.ru
    volumes:
      - ~/mtproxy_data:/data
EOF

# Запускаем через docker-compose
docker-compose up -d
