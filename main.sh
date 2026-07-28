#!/bin/bash

echo "========================================="
echo "  Запуск MTProxy через официальный Docker-образ"
echo "========================================="

# 1. Останавливаем и удаляем старые контейнеры
echo "🧹 Очистка старых контейнеров..."
docker rm -f mtproto-proxy mtproto-proxy-2 2>/dev/null || true

# 2. Запускаем первый прокси на порту 443
echo "🚀 Запуск прокси 1 (порт 443)..."
docker run -d \
  --name=mtproto-proxy \
  --restart=always \
  -p 443:443 \
  -v mtproto-proxy-config:/data \
  -e SECRET=ee7765622e796f74612e72755b744f13 \
  -e TAG=8b654af431191c0e4f9e64c44f0d3d1e \
  -e WORKERS=2 \
  telegrammessenger/proxy:latest

# 3. Запускаем второй прокси на порту 8443
echo "🚀 Запуск прокси 2 (порт 8443)..."
docker run -d \
  --name=mtproto-proxy-2 \
  --restart=always \
  -p 8443:443 \
  -v mtproto-proxy-config-2:/data \
  -e SECRET=c741a811908c5b4238dee60fc14c784c \
  -e TAG=b62807b6682914bcbd6ef432b20b89f4 \
  -e WORKERS=2 \
  telegrammessenger/proxy:latest

# 4. Проверяем статус
echo ""
echo "📊 Статус контейнеров:"
sleep 3
docker ps --filter "name=mtproto-proxy" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 5. Показываем логи со ссылками
echo ""
echo "📋 Логи прокси 1:"
docker logs mtproto-proxy 2>&1 | grep -E "(tg://proxy|Secret|External IP)"

echo ""
echo "📋 Логи прокси 2:"
docker logs mtproto-proxy-2 2>&1 | grep -E "(tg://proxy|Secret|External IP)"

# 6. Проверяем статистику
echo ""
echo "📊 Статистика прокси 1:"
docker exec mtproto-proxy curl -s http://localhost:2398/stats 2>/dev/null || echo "Статистика временно недоступна"

echo ""
echo "📊 Статистика прокси 2:"
docker exec mtproto-proxy-2 curl -s http://localhost:2398/stats 2>/dev/null || echo "Статистика временно недоступна"

echo ""
echo "========================================="
echo "✅ Прокси запущены!"
echo "========================================="
echo "📱 Ссылки для подключения:"
echo "   tg://proxy?server=185.229.66.115&port=443&secret=ee7765622e796f74612e72755b744f13"
echo "   tg://proxy?server=185.229.66.115&port=8443&secret=c741a811908c5b4238dee60fc14c784c"
echo ""
echo "📋 Для просмотра полных логов:"
echo "   docker logs mtproto-proxy"
echo "   docker logs mtproto-proxy-2"
echo "========================================="
