cat << 'EOF' > fix_tg_proxy.sh
#!/bin/bash

CONFIG_FILE="/etc/mtg-proxy/config.toml"
IMAGE_NAME="ghcr.io/mhasanei/mtg-multi:latest"
DOMAIN="web.yota.ru"
IP_PROXY="185.229.66.115"

echo "=== 1. Генерация нового секретного ключа для $DOMAIN ==="
NEW_SECRET=$(docker run --rm $IMAGE_NAME generate secret tls $DOMAIN 2>/dev/null | grep -E '^[0-9a-fA-F]{64,}')

if [ -z "$NEW_SECRET" ]; then
    echo "Ошибка: Не удалось сгенерировать секрет через Docker. Проверьте интернет-соединение."
    exit 1
fi
echo "Успешно! Новый секрет: $NEW_SECRET"

echo "=== 2. Обновление конфигурационного файла $CONFIG_FILE ==="
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Ошибка: Файл $CONFIG_FILE не найден!"
    exit 1
fi

# Делаем бэкап старого конфига на всякий случай
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"

# Заменяем старую строку secret на новую
sed -i "s/^secret = .*/secret = \"$NEW_SECRET\"/" "$CONFIG_FILE"
echo "Конфигурация успешно обновлена."

echo "=== 3. Перезапуск Docker-контейнера ==="
echo "Остановка и удаление старого tg-proxy..."
docker stop tg-proxy && docker rm tg-proxy

echo "Запуск нового контейнера с правильными параметрами..."
docker run -d \
  --name tg-proxy \
  --restart=always \
  -p 8443:8443 \
  --add-host="${DOMAIN}:${IP_PROXY}" \
  -v "/etc/mtg-proxy/:/config:ro" \
  $IMAGE_NAME run /config/config.toml

echo "=== 4. Скрипт завершил работу! ==="
echo "Вывод логов (нажмите Ctrl+C для выхода):"
echo "--------------------------------------"
sleep 2
docker logs -f tg-proxy
EOF

chmod +x fix_tg_proxy.sh && ./fix_tg_proxy.sh
