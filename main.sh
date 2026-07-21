#!/bin/bash

# Прерывать выполнение при любой ошибке
set -e

# 1. Создаем директорию для конфигурации, если её нет
sudo mkdir -p /etc/mtg-proxy

# 2. Записываем конфигурацию в файл config.toml
sudo tee /etc/mtg-proxy/config.toml > /dev/null << 'EOF'
secret = "eec741a811908c5b4238dee60fc14c784c7765622e796f74612e7275"
bind-to = "0.0.0.0:3128"

[promoted]
tag = "b62807b6682914bcbd6ef432b20b89f4"
EOF

echo "Конфигурация успешно сохранена в /etc/mtg-proxy/config.toml"

# 3. Удаляем старый контейнер, если он существует (игнорируем ошибку, если контейнера нет)
echo "Останавливаем и удаляем старый контейнер..."
sudo docker rm -f mtproto-proxy-8443 2>/dev/null || true

# 4. Запускаем новый контейнер с правильным синтаксисом
echo "Запускаем новый контейнер mtg v2..."
sudo docker run -d \
    --name="mtproto-proxy-8443" \
    --restart=always \
    -p "8443:3128" \
    -v "/etc/mtg-proxy:/config:ro" \
    nineseconds/mtg:2 \
    run /config/config.toml

echo "Прокси успешно развернут и запущен на порту 8443!"
