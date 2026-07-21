#!/bin/bash

# ============================================
# Установка MTG Proxy (nineseconds/mtg:1)
# С поддержкой Fake-TLS и Рекламного тега
# Порт: 8443
# ============================================

set -e  # Остановка при любой ошибке

# Конфигурация
IP="185.229.66.115"
EXTERNAL_PORT="8443"
CONTAINER_NAME="mtproto-proxy-8443"
SECRET="eec741a811908c5b4238dee60fc14c784c7765622e796f74612e7275"
AD_TAG="b62807b6682914bcbd6ef432b20b89f4"

echo "🔄 Удаление старого контейнера..."
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

echo "🐳 Запуск оптимизированного MTG:1..."
sudo docker run -d \
    --name="$CONTAINER_NAME" \
    --restart=always \
    -p "${EXTERNAL_PORT}:3128" \
    -e MTG_BUFFER_READ="512KB" \
    -e MTG_BUFFER_WRITE="512KB" \
    nineseconds/mtg:1 \
    run \
    -4 "${IP}:${EXTERNAL_PORT}" \
    "$SECRET" \
    "$AD_TAG"

echo "🔍 Проверка статуса через 3 секунды..."
sleep 3
docker ps --filter "name=${CONTAINER_NAME}"

echo "📋 Ссылка для подключения:"
echo "tg://proxy?port=${EXTERNAL_PORT}&secret=${SECRET}&server=${IP}"
