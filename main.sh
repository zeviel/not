cat << 'EOF' > fix_tg_proxy_v2.sh
#!/bin/bash

CONFIG_FILE="/etc/mtg-proxy/config.toml"
IMAGE_NAME="ghcr.io/mhasanei/mtg-multi:latest"
DOMAIN="web.yota.ru"
IP_PROXY="185.229.66.115"

echo "=== 1. Создание корректного FakeTLS секрета ==="
# Префикс ee + случайный хэш на 32 знака + hex-код домена web.yota.ru
HEX_DOMAIN=$(echo -n "$DOMAIN" | xxd -p | tr -d '\n')
RANDOM_HASH=$(openssl rand -hex 16)
NEW_SECRET="ee${RANDOM_HASH}${HEX_DOMAIN}"

echo "Успешно! Сгенерирован ключ: $NEW_SECRET"

echo "=== 2. Обновление конфигурационного файла $CONFIG_FILE ==="
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Ошибка: Файл $CONFIG_FILE не найден!"
    exit 1
fi

# Бекап старой конфигурации
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"

# Замена секретного ключа
sed -i "s/^secret = .*/secret = \"$NEW_SECRET\"/" "$CONFIG_FILE"
echo "Конфигурация успешно обновлена."

echo "=== 3. Перезапуск Docker-контейнера ==="
echo "Остановка и удаление старого tg-proxy..."
docker stop tg-proxy && docker rm tg-proxy 2>/dev/null

echo "Запуск нового контейнера с правильными параметрами..."
docker run -d \
  --name tg-proxy \
  --restart=always \
  -p 8443:8443 \
  --add-host="${DOMAIN}:${IP_PROXY}" \
  -v "/etc/mtg-proxy/:/config:ro" \
  $IMAGE_NAME run /config/config.toml

echo "=== 4. Проверка статуса ==="
sleep 2
echo "Вывод логов нового контейнера (нажмите Ctrl+C для выхода):"
echo "--------------------------------------"
docker logs -f tg-proxy
EOF

chmod +x fix_tg_proxy_v2.sh && ./fix_tg_proxy_v2.sh
