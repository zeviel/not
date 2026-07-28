# 1. Создаем папку и скачиваем официальные файлы конфигурации прямо туда
mkdir -p /etc/telegram
curl -s https://telegram.org -o /etc/telegram/proxy-secret

# 2. Удаляем старые зависшие контейнеры
docker rm -f mtproto-proxy mtproto-proxy-2 2>/dev/null || true

# 3. Запускаем Контейнер 1 на порту 443
docker rm -f mtproto-proxy mtproto-proxy-2 2>/dev/null || true

docker rm -f mtproto-proxy mtproto-proxy-2 2>/dev/null || true

# Контейнер 1 (порт 443) — ссылка вставлена строго в конец команды, как требует синтаксис
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
  -M 1 \
  -C https://core.telegram.org/getProxyConfig

# Контейнер 2 (порт 8443)
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
  -M 1 \
  -C https://core.telegram.org/getProxyConfig
