docker stop mtproto-proxy-8443 && docker rm mtproto-proxy-8443

docker run -d \
  --name mtproto-proxy-8443 \
  --restart=always \
  -p 8443:443 \
  -e SECRET="c741a811908c5b4238dee60fc14c784c" \
  -e SECRET_HOST="web.yota.ru" \
  -e TAG="b62807b6682914bcbd6ef432b20b89f4" \
  -e MTG_BIND_TO="0.0.0.0:443" \
  -e PUBLIC_IPV4="185.229.66.115" \
  -e IP_OVERRIDE="185.229.66.115" \
  ghcr.io/mhsanaei/mtg-multi:latest
