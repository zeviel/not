docker rm -f mtproto-proxy mtproto-proxy-2 2>/dev/null || true

# Контейнер 1: на 443 порту с секретом ee7765622e...
docker run -d \
  --name=mtproto-proxy \
  --restart=always \
  -p 443:3128 \
  9seconds/mtg:2 run ee7765622e796f74612e72755b744f13 -a 8b65a4af31191c0e4f9e64c44f0d3d1e

# Контейнер 2: на 8443 порту со старым секретом c741a81190...
docker run -d \
  --name=mtproto-proxy-2 \
  --restart=always \
  -p 8443:3128 \
  9seconds/mtg:2 run c741a811908c5b4238dee60fc14c784c -a b62807b6682914bcbd6ef432b20b89f4
