docker run -d -p 8443:8443 --name=tg-proxy --restart=always \
  -e SECRET="c741a811908c5b4238dee60fc14c784c" \
  -e TAG="b62807b6682914bcbd6ef432b20b89f4" \
  -e MTP_PORT=8443 \
  seriyps/mtproto-proxy:latest
