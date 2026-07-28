#!/bin/bash

# Останавливаем и удаляем старые контейнеры
echo "🧹 Очистка старых контейнеров..."
docker rm -f mtproto-proxy mtproto-proxy-2 2>/dev/null || true

# 1. Запускаем Контейнер 1 на порту 443
echo "🚀 Запуск прокси 1 (порт 443)..."
docker run -d \
  --name=mtproto-proxy \
  --restart=always \
  -p 443:443 \
  -v mtproto-proxy-config:/data \
  -e SECRET=ee7765622e796f74612e72755b744f13 \
  -e TAG=8b65a4af31191c0e4f9e64c44f0d3d1e \
  -e WORKERS=2 \
  telegrammessenger/proxy:latest

# 2. Запускаем Контейнер 2 на порту 8443
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

# 3. Проверяем статус
sleep 3
echo -e "\n📊 Статус контейнеров:"
docker ps --filter "name=mtproto-proxy" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 4. Показываем логи (там будут ссылки для подключения)
echo -e "\n📋 Логи прокси 1:"
docker logs mtproto-proxy 2>&1 | grep -E "(tg://proxy|Secret)"

echo -e "\n📋 Логи прокси 2:"
docker logs mtproto-proxy-2 2>&1 | grep -E "(tg://proxy|Secret)"

# 5. Информация для подключения
echo -e "\n✅ Прокси успешно запущены!"
echo "=========================================="
echo "🔹 Прокси 1 (порт 443):"
echo "   Секрет: ee7765622e796f74612e72755b744f13"
echo "   Ссылка: tg://proxy?server=ВАШ_IP&port=443&secret=ee7765622e796f74612e72755b744f13"
echo ""
echo "🔹 Прокси 2 (порт 8443):"
echo "   Секрет: c741a811908c5b4238dee60fc14c784c"
echo "   Ссылка: tg://proxy?server=ВАШ_IP&port=8443&secret=c741a811908c5b4238dee60fc14c784c"
echo "=========================================="
