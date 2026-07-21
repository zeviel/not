# 1. Очищаем старый контейнер
docker rm -f mtproto-proxy-8443 2>/dev/null || true

# 2. Запускаем mtg:1 с правильным позиционным синтаксисом
docker run -d \
  --name="mtproto-proxy-8443" \
  --restart=always \
  -p "8443:8443" \
  nineseconds/mtg:1 \
  run \
  "eec741a811908c5b4238dee60fc14c784c7765622e796f74612e7275" \
  "b62807b6682914bcbd6ef432b20b89f4"



docker logs mtproto-proxy-8443
