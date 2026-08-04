docker stop tg-proxy && docker rm -f tg-proxy

docker run -d --restart=always --name tg-proxy \
  -p 8443:443 \
  -e SECRET="c741a811908c5b4238dee60fc14c784c" \
  -e TAG="b62807b6682914bcbde6f432b20b89f4" \
  -e TLS_DOMAIN="web.yota.ru" \
  seriyps/mtproto-proxy:latest
