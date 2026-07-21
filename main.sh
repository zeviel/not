#!/bin/bash

# ============================================
# Установка MTG Proxy (nineseconds/mtg:1)
# С поддержкой промо-каналов (AD_TAG)
# Домен: web.yota.ru
# Порт: 8443
# ============================================

set -e  # Остановка при любой ошибке

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}🚀 Установка MTG Proxy v1 (web.yota.ru)${NC}"
echo -e "${GREEN}============================================${NC}"

# Конфигурация
DOMAIN="web.yota.ru"
EXTERNAL_PORT="8443"
CONTAINER_NAME="mtproto-proxy-8443"
AD_TAG="b62807b6682914bcbd6ef432b20b89f4"

# Шаг 1: Правильная генерация Fake-TLS секрета (ee + 16 бит хеш + hex домена)
echo -e "${YELLOW}🔑 Шаг 1: Генерация секрета для домена ${DOMAIN}...${NC}"

HEX_KEY="c741a811908c5b4238dee60fc14c784c"
HEX_DOMAIN=$(echo -n "$DOMAIN" | xxd -p | tr -d '\n')
SECRET="ee${HEX_KEY}${HEX_DOMAIN}"

echo -e "${GREEN}✅ Секрет сгенерирован: ${SECRET}${NC}"

# Шаг 2: Остановка и удаление старого контейнера (если есть)
echo -e "${YELLOW}🔄 Шаг 2: Остановка и удаление старого контейнера...${NC}"
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true

# Шаг 3: Запуск контейнера v1 (передача параметров аргументами, порт 3128 внутри)
echo -e "${YELLOW}🐳 Шаг 3: Запуск контейнера mtg:1...${NC}"
sudo docker run -d \
    --name="$CONTAINER_NAME" \
    --restart=always \
    -p "${EXTERNAL_PORT}:3128" \
    nineseconds/mtg:1 \
    --bind 0.0.0.0:3128 \
    --adtag "${AD_TAG}" \
    "${SECRET}"

echo -e "${GREEN}✅ Контейнер запущен!${NC}"

# Шаг 4: Проверка статуса
echo -e "${YELLOW}🔍 Шаг 4: Проверка статуса...${NC}"
sleep 2

if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${GREEN}✅ Контейнер работает:${NC}"
    docker ps --filter "name=${CONTAINER_NAME}"
else
    echo -e "${RED}❌ Контейнер не запустился! Проверьте логи:${NC}"
    docker logs "$CONTAINER_NAME"
    exit 1
fi

# Шаг 5: Показ логов
echo -e "${YELLOW}📋 Шаг 5: Последние логи...${NC}"
docker logs "$CONTAINER_NAME" | tail -20

# Шаг 6: Ссылка для подключения
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}✅ Установка завершена!${NC}"
echo -e "${GREEN}============================================${NC}"
echo -e "📱 Ссылка для подключения:"
echo -e "${YELLOW}tg://proxy?server=${DOMAIN}&port=${EXTERNAL_PORT}&secret=${SECRET}${NC}"
echo ""
echo -e "🔧 Или через IP:"
echo -e "${YELLOW}tg://proxy?server=185.229.66.115&port=${EXTERNAL_PORT}&secret=${SECRET}${NC}"
echo -e "${GREEN}============================================${NC}"
