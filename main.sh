cat << 'EOF' > ~/install_mtproxy.sh
#!/bin/bash
set -e

echo "[1/6] Зачистка старых контейнеров и папок..."
docker rm -f tg-proxy mtproto-proxy 2>/dev/null || true
rm -rf ~/MTProxy

echo "[2/6] Обновление пакетов и установка зависимостей сборки..."
apt-get update -y
apt-get install -y git curl build-essential libssl-dev zlib1g-dev

echo "[3/6] Клонирование официального репозитория Telegram..."
cd ~
git clone https://github.com
cd MTProxy

echo "[4/6] Компиляция исходного кода (это займет около 30 секунд)..."
make

echo "[5/6] Переход в папку сборки и скачивание конфигурации Telegram..."
cd objs/bin
curl -s https://telegram.org -o proxy-secret
curl -s https://telegram.org -o proxy-multi.conf

echo "[6/6] Запуск MTProto-прокси в фоновом режиме..."
nohup ./mtproto-proxy -u nobody -p 8888 -H 8443 \
  -S c741a811908c5b4238dee60fc14c784c \
  -P b62807b6682914bcbd6ef432b20b89f4 \
  --aes-pwd proxy-secret proxy-multi.conf -M 1 > proxy.log 2>&1 &

echo "--------------------------------------------------------"
echo " Скрипт выполнен! Ждем 5 секунд для проверки логов..."
echo "--------------------------------------------------------"
sleep 5
tail -n 20 proxy.log
EOF

chmod +x ~/install_mtproxy.sh
~/install_mtproxy.sh
