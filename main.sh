#!/bin/bash
docker rm -f mtproto-proxy mtproto-proxy-2
# 1. Создаем папку для конфигов
mkdir -p /etc/telegram

# 2. Скачиваем правильные файлы конфигурации
echo "Загрузка конфигурационных файлов..."
curl -s https://core.telegram.org/getProxySecret -o /etc/telegram/proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o /etc/telegram/proxy-config

# Проверяем, что файлы загружены
if [[ ! -s /etc/telegram/proxy-secret ]] || [[ ! -s /etc/telegram/proxy-config ]]; then
    echo "Ошибка: не удалось загрузить конфигурационные файлы"
    exit 1
fi

# 3. Останавливаем и удаляем старые контейнеры
echo "Остановка старых контейнеров..."
docker rm -f mtproto-proxy mtproto-proxy-2 2>/dev/null || true

# 4. Запускаем Контейнер 1 на порту 443
echo "Запуск первого прокси (порт 443)..."
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

# 5. Запускаем Контейнер 2 на порту 8443
echo "Запуск второго прокси (порт 8443)..."
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

# 6. Проверяем статус
echo -e "\nПроверка статуса контейнеров:"
docker ps --filter "name=mtproto-proxy"

# 7. Ждем 3 секунды для инициализации
sleep 3

# 8. Выводим логи для проверки
echo -e "\n📋 Логи первого прокси:"
docker logs mtproto-proxy 2>&1 | tail -10

echo -e "\n📋 Логи второго прокси:"
docker logs mtproto-proxy-2 2>&1 | tail -10

# 9. Информация для подключения
echo -e "\n✅ Прокси запущены!"
echo "=========================================="
echo "🔹 Прокси 1 (порт 443):"
echo "   Secret: ee7765622e796f74612e72755b744f13"
echo "   Tag: 8b65a4af31191c0e4f9e64c44f0d3d1e"
echo ""
echo "🔹 Прокси 2 (порт 8443):"
echo "   Secret: c741a811908c5b4238dee60fc14c784c"
echo "   Tag: b62807b6682914bcbd6ef432b20b89f4"
echo "=========================================="
