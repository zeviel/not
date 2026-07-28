# 1. Удаляем следы прошлых попыток и возвращаемся в корень репозитория
cd ~/MTProxy 2>/dev/null || cd /MTProxy 2>/dev/null || cd $(pwd)

# 2. Очищаем старую сборку и запускаем компиляцию заново
make clean && make

# 3. Переходим в правильную, созданную компилятором папку с бинарником
cd objs/bin

# 4. Скачиваем официальные конфигурационные файлы Telegram прямо сюда
curl -s https://core.telegram.org/getProxySecret -o proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf

# 5. Запускаем прокси с вашим секретом и рекламным тегом в фоновом режиме (через nohup)
nohup ./mtproto-proxy -u nobody -p 8888 -H 8443 \
  -S c741a811908c5b4238dee60fc14c784c \
  -P b62807b6682914bcbd6ef432b20b89f4 \
  --aes-pwd proxy-secret proxy-multi.conf -M 1 > proxy.log 2>&1 &
