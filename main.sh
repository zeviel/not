#!/bin/bash

echo "========================================="
echo "  MTProxy на Docker (с привилегиями)"
echo "========================================="

# 1. Очистка
echo "🧹 Очистка старых контейнеров..."
docker rm -f mtproto-proxy mtproto-proxy-2 2>/dev/null || true

# 2. Системные лимиты (для гарантии)
echo "⚙️ Настройка лимитов..."
echo "fs.file-max = 2097152" >> /etc/sysctl.conf
sysctl -p

echo "root soft nofile 65536" >> /etc/security/limits.conf
echo "root hard nofile 65536" >> /etc/security/limits.conf

# 3. Запуск первого прокси (с привилегиями)
echo "🚀 Запуск прокси 1 (порт 443)..."
docker run -d \
  --name=mtproto-proxy \
  --restart=always \
  --privileged \
  --ulimit nofile=65536:65536 \
  -p 443:443 \
  -v mtproto-proxy-config:/data \
  -e SECRET=ee7765622e796f74612e72755b744f13 \
  -e TAG=8b65a4af31191c0e4f9e64c44f0d3d1e \
  -e WORKERS=2 \
  telegrammessenger/proxy:latest

# 4. Запуск второго прокси (с привилегиями)
echo "🚀 Запуск прокси 2 (порт 8443)..."
docker run -d \
  --name=mtproto-proxy-2 \
  --restart=always \
  --privileged \
  --ulimit nofile=65536:65536 \
  -p 8443:443 \
  -v mtproto-proxy-config-2:/data \
  -e SECRET=c741a811908c5b4238dee60fc14c784c \
  -e TAG=b62807b6682914bcbd6ef432b20b89f4 \
  -e WORKERS=2 \
  telegrammessenger/proxy:latest

# 5. Проверка
echo "⏳ Ожидание запуска..."
sleep 5

echo ""
echo "📊 Статус контейнеров:"
docker ps --filter "name=mtproto-proxy" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "📋 Логи первого прокси:"
docker logs mtproto-proxy 2>&1 | grep -E "tg://proxy|Secret|External IP|Starting proxy|fatal"

echo ""
echo "📋 Логи второго прокси:"
docker logs mtproto-proxy-2 2>&1 | grep -E "tg://proxy|Secret|External IP|Starting proxy|fatal"

echo ""
echo "📊 Статистика:"
sleep 2
docker exec mtproto-proxy curl -s http://localhost:2398/stats 2>/dev/null || echo "⏳ Статистика временно недоступна"

echo ""
echo "========================================="
echo "✅ Ваши прокси:"
echo "tg://proxy?server=185.229.66.115&port=443&secret=ee7765622e796f74612e72755b744f13"
echo "tg://proxy?server=185.229.66.115&port=8443&secret=c741a811908c5b4238dee60fc14c784c"
echo "========================================="
