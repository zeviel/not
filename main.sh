# Останавливаем и удаляем падающий контейнер
docker stop tg-proxy && docker rm -f tg-proxy

# Создаем папку для данных на хосте
mkdir -p ~/mtproxy_data

# Запускаем контейнер с томом, правами на запись и чистым окружением
docker run -d --restart=always --name tg-proxy \
  -p 8443:443 \
  -v ~/mtproxy_data:/data \
  -e SECRET="c741a811908c5b4238dee60fc14c784c" \
  -e TAG="b62807b6682914bcbde6f432b20b89f4" \
  -e TLS_DOMAIN="web.yota.ru" \
  seriyps/mtproto-proxy:latest
