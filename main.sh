#!/bin/bash

# ============================================
# Установка MTG Proxy (nineseconds/mtg:2)
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
echo -e "${GREEN}🚀 Установка MTG Proxy (web.yota.ru)${NC}"
echo -e "${GREEN}============================================${NC}"
docker stop mtproto-proxy-8443 && docker rm mtproto-proxy-8443

# Конфигурация
DOMAIN="web.yota.ru"
EXTERNAL_PORT="8443"
CONFIG_DIR="/etc/mtg-proxy"
CONFIG_FILE="${CONFIG_DIR}/config.toml"
CONTAINER_NAME="mtproto-proxy-8443"
AD_TAG="b73eb664e3dd95631c0b2112643d28d8"

# Шаг 1: Правильная генерация Fake-TLS секрета (ee + 16 бит хеш + hex домена)
echo -e "${YELLOW}🔑 Шаг 1: Генерация секрета для домена ${DOMAIN}...${NC}"

# Генерируем случайный 16-байтовый (32 символа) hex-хеш
HEX_KEY=$(openssl rand -hex 16)
# Переводим домен в HEX-формат
HEX_DOMAIN=$(echo -n "$DOMAIN" | xxd -p | tr -d '\n')
# Собираем финальный SECRET
SECRET="ee${HEX_KEY}${HEX_DOMAIN}"

echo -e "${GREEN}✅ Секрет сгенерирован: ${SECRET}${NC}"

# Шаг 2: Создание конфигурационного файла
echo -e "${YELLOW}📁 Шаг 2: Создание конфигурационного файла...${NC}"

# Создаём папку если её нет
sudo mkdir -p "$CONFIG_DIR"

# Записываем конфиг
sudo tee "$CONFIG_FILE" > /dev/null <<EOF
secret = "${SECRET}"
bind-to = "0.0.0.0:3128"
ad-tag = "${AD_TAG}"
EOF

echo -e "${GREEN}✅ Конфиг создан: ${CONFIG_FILE}${NC}"
cat "$CONFIG_FILE"

# Шаг 3: Остановка и удаление старого контейнера (если есть)
echo -e "${YELLOW}🔄 Шаг 3: Остановка и удаление старого контейнера...${NC}"
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true

# Шаг 4: Запуск контейнера (Добавлен флаг -c для указания пути к конфигу)
echo -e "${YELLOW}🐳 Шаг 4: Запуск контейнера...${NC}"
sudo docker run -d \
    --name="$CONTAINER_NAME" \
    --restart=always \
    -p "${EXTERNAL_PORT}:3128" \
    -v "${CONFIG_DIR}:/config:ro" \
    nineseconds/mtg:2 \
    run -c /config/config.toml

echo -e "${GREEN}✅ Контейнер запущен!${NC}"

# Шаг 5: Проверка статуса
echo -e "${YELLOW}🔍 Шаг 5: Проверка статуса...${NC}"
sleep 2

if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${GREEN}✅ Контейнер работает:${NC}"
    docker ps --filter "name=${CONTAINER_NAME}"
else
    echo -e "${RED}❌ Контейнер не запустился! Проверьте логи:${NC}"
    docker logs "$CONTAINER_NAME"
    exit 1
fi

# Шаг 6: Показ логов
echo -e "${YELLOW}📋 Шаг 6: Последние логи...${NC}"
docker logs "$CONTAINER_NAME" | tail -20

# Шаг 7: Ссылка для подключения
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}✅ Установка завершена!${NC}"
echo -e "${GREEN}============================================${NC}"
echo -e "📱 Ссылка для подключения:"
echo -e "${YELLOW}tg://proxy?server=${DOMAIN}&port=${EXTERNAL_PORT}&secret=${SECRET}${NC}"
echo ""
echo -e "🔧 Или через IP:"
echo -e "${YELLOW}tg://proxy?server=185.229.66.115&port=${EXTERNAL_PORT}&secret=${SECRET}${NC}"
echo -e "${GREEN}============================================${NC}"
