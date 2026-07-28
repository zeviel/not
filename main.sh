docker rm -f mtproto-proxy mtproto-proxy-2 2>/dev/null || true

# Создаем папки для конфигов на хосте, чтобы прокси не ругался на их отсутствие
mkdir -p /etc/telegram
curl -s https://telegram.org -o /etc/telegram/proxy-secret
curl -s https://telegram.org -o /etc/telegram/proxy-multi.conf

# Запуск первого контейнера напрямую через бинарник с флагом -M 1
docker run -d \
  --name=mtproto-proxy \
  --restart=always \
  -p 443:443 \
  -v /etc/telegram:/etc/telegram \
  --entrypoint /objs/bin/mtproto-proxy \
  telegrammessenger/proxy:latest \
  -u nobody -p 8888 -H 443 \
  -S ee7765622e796f74612e72755b744f13 \
  -P 8b65a4af31191c0e4f9e64c44f0d3d1e \
  --aes-pwd /etc/telegram/proxy-secret /etc/telegram/proxy-multi.conf -M 1

docker run -d \
  --name=mtproto-proxy-2 \
  --restart=always \
  -p 8443:443 \
  -v /etc/telegram:/etc/telegram \
  --entrypoint /objs/bin/mtproto-proxy \
  telegrammessenger/proxy:latest \
  -u nobody -p 8888 -H 443 \
  -S c741a811908c5b4238dee60fc14c784c \
  -P b62807b6682914bcbd6ef432b20b89f4 \
  --aes-pwd /etc/telegram/proxy-secret /etc/telegram/proxy-multi.conf -M 1
