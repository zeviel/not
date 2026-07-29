docker stop tg-proxy && docker rm tg-proxy
docker run -d \
  --name tg-proxy \
  --restart=always \
  -p 8443:8443 \
  ghcr.io/mhsanaei/mtg-multi:latest \
  run \
  --secret "eec741a811908c5b4238dee60fc14c784c7765622e796f74612e7275" \
  --bind-to "[::]:8443" \
  --public-ipv6 "2a0a:9300:1:1726::1" \
  --public-ipv4 "185.229.66.115" \
  --allow-fallback-on-unknown-dc \
  --ad-tag "b62807b6682914bcbd6ef432b20b89f4"
