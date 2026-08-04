
docker stop tg-proxy && docker rm -f tg-proxy

# Перезапускаем с переменной SECRET
docker run -d --restart=always --name tg-proxy \
  -p 8443:443 \
  --privileged \
  --ulimit nofile=65535:65535 \
  -e SECRET="eec741a811908c5b4238dee60fc14c784c7765622e796f74612e7275" \
  -e TAG="b62807b6682914bcbde6f432b20b89f4" \
  telegrammessenger/proxy:latest
