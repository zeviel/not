docker rm -f tg-proxy
docker run -d -p 8443:8443 --name=tg-proxy --restart=always \
  --sysctl net.ipv6.conf.all.disable_ipv6=1 \
  --dns 8.8.8.8 \
  -e MTP_PORT=8443 \
  -e MTP_SECRET="c741a811908c5b4238dee60fc14c784c" \
  -e MTP_TAG="b62807b6682914bcbd6ef432b20b89f4" \
  seriyps/mtproto-proxy:latest

