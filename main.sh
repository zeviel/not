docker rm -f mtproto-proxy mtproto-proxy-2 2>/dev/null || true

# 1. Запуск первого прокси на 443 порту
docker run -d \
  --name=mtproto-proxy \
  --restart=always \
  -p 443:3128 \
  nineseconds/mtg:2 simple-run 0.0.0.0:3128 ee7765622e796f74612e72755b744f13 -a 8b65a4af31191c0e4f9e64c44f0d3d1e

# 2. Запуск второго прокси на 8443 порту
docker run -d \
  --name=mtproto-proxy-2 \
  --restart=always \
  -p 8443:3128 \
  nineseconds/mtg:2 simple-run 0.0.0.0:3128 c741a811908c5b4238dee60fc14c784c -a b62807b6682914bcbd6ef432b20b89f4
