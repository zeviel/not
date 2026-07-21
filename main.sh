docker run -d -p 8443:443 --name=tg-proxy --restart=always \
  -e SECRET="c741a811908c5b4238dee60fc14c784c" \
  -e TAG="b62807b6682914bcbd6ef432b20b89f4" \
  -e TLS_DOMAIN="web.yota.ru" \
  telegrammessenger/proxy:2.0beta
