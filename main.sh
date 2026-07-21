# 1. Удаляем упавший официальный контейнер
docker rm -f mtproto-proxy-8443 2>/dev/null || true

# 2. Запускаем mtg:1 с корректным флагом --adtag
docker run -d \
  --name="mtproto-proxy-8443" \
  --restart=always \
  -p "8443:3128" \
  nineseconds/mtg:1 \
  run \
  --adtag "b62807b6682914bcbd6ef432b20b89f4" \
  "eec741a811908c5b4238dee60fc14c784c7765622e796f74612e7275"



docker logs mtproto-proxy-8443
