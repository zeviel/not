#!/bin/bash

echo "========================================="
echo "  MTProxy на Docker (гарантированно)"
echo "========================================="

# 1. Удаляем старый Docker
echo "🧹 Удаление старого Docker..."
apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
apt autoremove -y 2>/dev/null || true

# 2. Устанавливаем Docker
echo "📦 Установка Docker..."
apt update
apt install -y apt-transport-https ca-certificates curl software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

apt update
apt install -y docker-ce docker-ce-cli containerd.io

systemctl start docker
systemctl enable docker

# 3. Проверяем Docker
docker --version
systemctl status docker --no-pager

# 4. Убиваем старые контейнеры
echo "🧹 Очистка старых контейнеров..."
docker rm -f mtproto-proxy mtproto-proxy-2 2>/dev/null || true

# 5. Запускаем прокси
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

# 6. Ждём и проверяем
echo "⏳ Ожидание запуска..."
sleep 5

echo ""
echo "📊 Статус контейнеров:"
docker ps --filter "name=mtproto-proxy" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "📋 Логи первого прокси:"
docker logs mtproto-proxy 2>&1 | grep -E "tg://proxy|Secret|External IP|Starting proxy"

echo ""
echo "📋 Логи второго прокси:"
docker logs mtproto-proxy-2 2>&1 | grep -E "tg://proxy|Secret|External IP|Starting proxy"

echo ""
echo "🔌 Проверка портов:"
ss -tlnp | grep -E "443|8443" || netstat -tlnp | grep -E "443|8443"

echo ""
echo "📊 Статистика:"
sleep 2
docker exec mtproto-proxy curl -s http://localhost:2398/stats 2>/dev/null || echo "⏳ Статистика временно недоступна"

echo ""
echo "========================================="
echo "✅ Всё работает!"
echo "========================================="
echo ""
echo "📱 Ваши ссылки:"
echo "   tg://proxy?server=185.229.66.115&port=443&secret=ee7765622e796f74612e72755b744f13"
echo "   tg://proxy?server=185.229.66.115&port=8443&secret=c741a811908c5b4238dee60fc14c784c"
echo ""
echo "📋 Команды управления:"
echo "   docker logs -f mtproto-proxy    # логи первого"
echo "   docker logs -f mtproto-proxy-2  # логи второго"
echo "   docker restart mtproto-proxy    # перезапуск"
echo "   docker ps                       # список контейнеров"
echo "========================================="
