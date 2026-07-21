# 1. Удаляем упавший официальный контейнер
docker rm -f mtproto-proxy-8443 2>/dev/null || true

# 2. Запускаем поддерживаемый Fake-TLS образ с вашим токеном
docker run -d \
  --name="mtproto-proxy-8443" \
  --restart=always \
  -p "8443:443" \
  -e SECRET="eec741a811908c5b4238dee60fc14c784c7765622e796f74612e7275" \
  -e AD_TAG="b62807b6682914bcbd6ef432b20b89f4" \
  -e WORKERS=2 \
  seriyps/mtproto-proxy:latest

docker logs mtproto-proxy-8443
