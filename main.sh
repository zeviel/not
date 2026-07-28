\# 1. Останавливаем и удаляем контейнеры
docker stop mtproto-proxy mtproto-proxy-2 2>/dev/null || true
docker rm mtproto-proxy mtproto-proxy-2 2>/dev/null || true

# 2. Увеличиваем системный лимит для Docker-демона
echo "fs.file-max = 2097152" >> /etc/sysctl.conf
sysctl -p

# 3. Увеличиваем пользовательский лимит
echo "root soft nofile 65536" >> /etc/security/limits.conf
echo "root hard nofile 65536" >> /etc/security/limits.conf

# 4. Перезапускаем Docker демон
systemctl restart docker

# 5. Запускаем прокси снова
docker run -d \
  --name=mtproto-proxy \
  --restart=always \
  -p 443:443 \
  -v mtproto-proxy-config:/data \
  -e SECRET=ee7765622e796f74612e72755b744f13 \
  -e TAG=8b654af431191c0e4f9e64c44f0d3d1e \
  -e WORKERS=2 \
  --ulimit nofile=65536:65536 \
  telegrammessenger/proxy:latest

# 1. Проверить статус контейнера
docker ps --filter "name=mtproto-proxy"

# 2. Посмотреть логи (предупреждение о лимитах должно исчезнуть)
docker logs mtproto-proxy 2>&1 | tail -20

# 3. Проверить статистику
docker exec mtproto-proxy curl -s http://localhost:2398/stats

# 4. Проверить, что порт слушается
ss -tlnp | grep 443

# 5. Проверить открытые файлы (лимит должен быть 65536)
docker exec mtproto-proxy sh -c "ulimit -n"

docker run -d \
  --name=mtproto-proxy-2 \
  --restart=always \
  -p 8443:443 \
  -v mtproto-proxy-config-2:/data \
  -e SECRET=c741a811908c5b4238dee60fc14c784c \
  -e TAG=b62807b6682914bcbd6ef432b20b89f4 \
  -e WORKERS=2 \
  --ulimit nofile=65536:65536 \
  telegrammessenger/proxy:latest

  
