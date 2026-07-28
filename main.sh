#!/bin/bash

# 1. Создаем папку для конфигов
mkdir -p /etc/telegram

# 2. Скачиваем ОБА файла конфигурации (как сказано в документации)
echo "📥 Загрузка конфигурационных файлов..."
curl -s https://core.telegram.org/getProxySecret -o /etc/telegram/proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o /etc/telegram/proxy-multi.conf

# Проверка загрузки
if [[ ! -s /etc/telegram/proxy-secret ]] || [[ ! -s /etc/telegram/proxy-multi.conf ]]; then
    echo "❌ Ошибка: не удалось загрузить файлы конфигурации"
    exit 1
fi
echo "✅ Конфигурационные файлы загружены"

# 3. Очищаем старые контейнеры
echo "🧹 Удаление старых контейнеров..."
docker rm -f mtproto-proxy mtproto-proxy-2 2>/dev/null || true

# 4. Запускаем Контейнер 1 (порт 443)
echo "🚀 Запуск прокси 1 (порт 443)..."
docker run -d \
  --name=mtproto-proxy \
  --restart=always \
  -p 443:443 \
  -v /etc/telegram:/etc/telegram \
  telegrammessenger/proxy:latest \
  -u nobody -p 8888 -H 443 \
  -S ee7765622e796f74612e72755b744f13 \
  -P 8b65a4af31191c0e4f9e64c44f0d3d1e \
  --aes-pwd /etc/telegram/proxy-secret /etc/telegram/proxy-multi.conf \
  -M 1

# 5. Запускаем Контейнер 2 (порт 8443)
echo "🚀 Запуск прокси 2 (порт 8443)..."
docker run -d \
  --name=mtproto-proxy-2 \
  --restart=always \
  -p 8443:443 \
  -v /etc/telegram:/etc/telegram \
  telegrammessenger/proxy:latest \
  -u nobody -p 8888 -H 443 \
  -S c741a811908c5b4238dee60fc14c784c \
  -P b62807b6682914bcbd6ef432b20b89f4 \
  --aes-pwd /etc/telegram/proxy-secret /etc/telegram/proxy-multi.conf \
  -M 1

# 6. Проверяем статус
sleep 3
echo -e "\n📊 Статус контейнеров:"
docker ps --filter "name=mtproto-proxy" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 7. Информация для подключения
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
echo ""
echo "📌 Важно: не забудьте зарегистрировать прокси в @MTProxybot,"
echo "   чтобы получить тег и включить статистику."
