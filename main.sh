#!/bin/bash

# 1. Создаем папку и скачиваем оба файла конфигурации
mkdir -p /etc/telegram
echo "📥 Загрузка конфигурационных файлов..."
curl -s https://core.telegram.org/getProxySecret -o /etc/telegram/proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o /etc/telegram/proxy-config

# Проверка загрузки
if [[ ! -s /etc/telegram/proxy-secret ]]; then
    echo "❌ Ошибка: не удалось загрузить proxy-secret"
    exit 1
fi
if [[ ! -s /etc/telegram/proxy-config ]]; then
    echo "❌ Ошибка: не удалось загрузить proxy-config"
    exit 1
fi
echo "✅ Конфигурационные файлы загружены"

# 2. Очищаем старые контейнеры
echo "🧹 Удаление старых контейнеров..."
docker rm -f mtproto-proxy mtproto-proxy-2 2>/dev/null || true

# 3. Запускаем Контейнер 1 на порту 443
echo "🚀 Запуск прокси 1 (порт 443)..."
docker run -d \
  --name=mtproto-proxy \
  --restart=always \
  -p 443:443 \
  -v /etc/telegram:/etc/telegram \
  --entrypoint /usr/local/bin/mtproto-proxy \
  telegrammessenger/proxy:latest \
  -u nobody -p 8888 -H 443 \
  -S ee7765622e796f74612e72755b744f13 \
  -P 8b65a4af31191c0e4f9e64c44f0d3d1e \
  --aes-pwd /etc/telegram/proxy-secret \
  -C /etc/telegram/proxy-config \
  -M 1

# 4. Запускаем Контейнер 2 на порту 8443
echo "🚀 Запуск прокси 2 (порт 8443)..."
docker run -d \
  --name=mtproto-proxy-2 \
  --restart=always \
  -p 8443:443 \
  -v /etc/telegram:/etc/telegram \
  --entrypoint /usr/local/bin/mtproto-proxy \
  telegrammessenger/proxy:latest \
  -u nobody -p 8888 -H 443 \
  -S c741a811908c5b4238dee60fc14c784c \
  -P b62807b6682914bcbd6ef432b20b89f4 \
  --aes-pwd /etc/telegram/proxy-secret \
  -C /etc/telegram/proxy-config \
  -M 1

# 5. Проверяем статус
sleep 3
echo -e "\n📊 Статус контейнеров:"
docker ps --filter "name=mtproto-proxy" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 6. Показываем логи
echo -e "\n📋 Логи прокси 1:"
docker logs mtproto-proxy 2>&1 | tail -5

echo -e "\n📋 Логи прокси 2:"
docker logs mtproto-proxy-2 2>&1 | tail -5

# 7. Информация для подключения
echo -e "\n✅ Прокси успешно запущены!"
echo "=========================================="
echo "🔹 Прокси 1 (порт 443):"
echo "   Секрет: ee7765622e796f74612e72755b744f13"
echo "   Тег: 8b65a4af31191c0e4f9e64c44f0d3d1e"
echo "   Ссылка: tg://proxy?server=ВАШ_IP&port=443&secret=ee7765622e796f74612e72755b744f13"
echo ""
echo "🔹 Прокси 2 (порт 8443):"
echo "   Секрет: c741a811908c5b4238dee60fc14c784c"
echo "   Тег: b62807b6682914bcbd6ef432b20b89f4"
echo "   Ссылка: tg://proxy?server=ВАШ_IP&port=8443&secret=c741a811908c5b4238dee60fc14c784c"
echo "=========================================="
