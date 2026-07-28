#!/bin/bash

# Простая версия без лишних проверок
mkdir -p /etc/telegram

# Скачиваем конфиги
curl -s https://core.telegram.org/getProxySecret -o /etc/telegram/proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o /etc/telegram/proxy-config

# Чистим старые контейнеры
docker rm -f mtproto-proxy mtproto-proxy-2 2>/dev/null || true

# Запускаем первый прокси (порт 443)
docker run -d \
  --name=mtproto-proxy \
  --restart=always \
  -p 443:443 \
  -v /etc/telegram:/etc/telegram \
  telegrammessenger/proxy:latest \
  -u nobody -p 8888 -H 443 \
  -S ee7765622e796f74612e72755b744f13 \
  -P 8b65a4af31191c0e4f9e64c44f0d3d1e \
  --aes-pwd /etc/telegram/proxy-secret \
  -C /etc/telegram/proxy-config \
  -M 1

# Запускаем второй прокси (порт 8443)
docker run -d \
  --name=mtproto-proxy-2 \
  --restart=always \
  -p 8443:443 \
  -v /etc/telegram:/etc/telegram \
  telegrammessenger/proxy:latest \
  -u nobody -p 8888 -H 443 \
  -S c741a811908c5b4238dee60fc14c784c \
  -P b62807b6682914bcbd6ef432b20b89f4 \
  --aes-pwd /etc/telegram/proxy-secret \
  -C /etc/telegram/proxy-config \
  -M 1

echo "✅ Прокси запущены!"
docker ps --filter "name=mtproto-proxy"
