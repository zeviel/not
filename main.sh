#!/bin/bash

set -e

echo "========================================="
echo "  Установка Docker + MTProxy"
echo "========================================="

# 1. Устанавливаем Docker
echo "📦 Установка Docker..."
apt update
apt install -y apt-transport-https ca-certificates curl software-properties-common

# Добавляем официальный репозиторий Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Устанавливаем Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io

# Проверяем установку
docker --version

# 2. Останавливаем и удаляем старые контейнеры
echo "🧹 Очистка старых контейнеров..."
docker rm -f mtproto-proxy mtproto-proxy-2 2>/dev/null || true

# 3. Запускаем первый прокси на порту 443
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

# 4. Запускаем второй прокси на порту 8443
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

# 5. Проверяем статус
echo ""
echo "📊 Статус контейнеров:"
sleep 5
docker ps --filter "name=mtproto-proxy" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 6. Показываем логи
echo ""
echo "📋 Логи прокси 1:"
docker logs mtproto-proxy 2>&1 | grep -E "(tg://proxy|Secret|External IP|Starting proxy)" || docker logs mtproto-proxy

echo ""
echo "📋 Логи прокси 2:"
docker logs mtproto-proxy-2 2>&1 | grep -E "(tg://proxy|Secret|External IP|Starting proxy)" || docker logs mtproto-proxy-2

# 7. Проверяем порты
echo ""
echo "🔌 Проверка открытых портов:"
ss -tlnp | grep -E "443|8443" || echo "⚠️  Порты не найдены. Проверьте firewall."

# 8. Проверяем статистику
echo ""
echo "📊 Статистика прокси 1:"
docker exec mtproto-proxy curl -s http://localhost:2398/stats 2>/dev/null || echo "⏳ Статистика ещё не готова (подождите немного)"

echo ""
echo "📊 Статистика прокси 2:"
docker exec mtproto-proxy-2 curl -s http://localhost:2398/stats 2>/dev/null || echo "⏳ Статистика ещё не готова (подождите немного)"

# 9. Настраиваем автообновление конфига
echo ""
echo "🔄 Настройка ежедневного обновления конфига..."
cat > /usr/local/bin/update-mtproxy-config.sh << 'EOF'
#!/bin/bash
docker restart mtproto-proxy mtproto-proxy-2
EOF
chmod +x /usr/local/bin/update-mtproxy-config.sh

if ! crontab -l 2>/dev/null | grep -q "update-mtproxy-config"; then
    (crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/update-mtproxy-config.sh") | crontab -
fi

echo ""
echo "========================================="
echo "✅ Установка завершена!"
echo "========================================="
echo ""
echo "📱 Ссылки для подключения:"
echo "   tg://proxy?server=185.229.66.115&port=443&secret=ee7765622e796f74612e72755b744f13"
echo "   tg://proxy?server=185.229.66.115&port=8443&secret=c741a811908c5b4238dee60fc14c784c"
echo ""
echo "📋 Для просмотра логов в реальном времени:"
echo "   docker logs -f mtproto-proxy"
echo "   docker logs -f mtproto-proxy-2"
echo ""
echo "🔄 Команды для управления:"
echo "   docker restart mtproto-proxy"
echo "   docker stop mtproto-proxy"
echo "   docker start mtproto-proxy"
echo "========================================="

# 10. Проверяем, что контейнеры работают
echo ""
echo "🔍 Проверка работающих контейнеров:"
docker ps | grep mtproto-proxy || echo "⚠️  Контейнеры не запущены!"
