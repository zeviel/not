\# 1. Останавливаем и удаляем контейнеры
docker stop mtproto-proxy mtproto-proxy-2 2>/dev/null || true
docker rm mtproto-proxy mtproto-proxy-2 2>/dev/null || true
sudo apt remove docker*&&sudo apt autoremove
# Устанавливаем зависимости для сборки
apt update
apt install -y git curl build-essential libssl-dev zlib1g-dev

# Клонируем репозиторий
git clone https://github.com/TelegramMessenger/MTProxy
cd MTProxy

# Собираем
make

# Переходим в папку с бинарником
cd objs/bin
# Создаём папку для конфигов
mkdir -p /etc/telegram

# Скачиваем секрет и конфиг
curl -s https://core.telegram.org/getProxySecret -o /etc/telegram/proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o /etc/telegram/proxy-multi.conf

# Проверяем, что файлы скачались
ls -la /etc/telegram/
cat > /etc/systemd/system/mtproto-proxy.service << 'EOF'
[Unit]
Description=MTProto Proxy
After=network.target

[Service]
Type=simple
WorkingDirectory=/root/MTProxy/objs/bin
ExecStart=/root/MTProxy/objs/bin/mtproto-proxy \
    -u nobody \
    -p 8888 \
    -H 443 \
    -S ee7765622e796f74612e72755b744f13 \
    -P 8b654af431191c0e4f9e64c44f0d3d1e \
    --aes-pwd /etc/telegram/proxy-secret /etc/telegram/proxy-multi.conf \
    -M 2
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/mtproto-proxy-2.service << 'EOF'
[Unit]
Description=MTProto Proxy 2 (port 8443)
After=network.target

[Service]
Type=simple
WorkingDirectory=/root/MTProxy/objs/bin
ExecStart=/root/MTProxy/objs/bin/mtproto-proxy \
    -u nobody \
    -p 8889 \
    -H 8443 \
    -S c741a811908c5b4238dee60fc14c784c \
    -P b62807b6682914bcbd6ef432b20b89f4 \
    --aes-pwd /etc/telegram/proxy-secret /etc/telegram/proxy-multi.conf \
    -M 2
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
# Добавляем в sysctl
echo "fs.file-max = 2097152" >> /etc/sysctl.conf
sysctl -p

# Добавляем лимиты для пользователя nobody
echo "nobody soft nofile 65536" >> /etc/security/limits.conf
echo "nobody hard nofile 65536" >> /etc/security/limits.conf

# Для текущей сессии
ulimit -n 65536
# Перезагружаем systemd
systemctl daemon-reload

# Запускаем первый прокси
systemctl start mtproto-proxy
systemctl enable mtproto-proxy

# Запускаем второй прокси
systemctl start mtproto-proxy-2
systemctl enable mtproto-proxy-2

# Проверяем статус
systemctl status mtproto-proxy
systemctl status mtproto-proxy-2

# Смотрим логи
journalctl -u mtproto-proxy -f
journalctl -u mtproto-proxy-2 -f
cat > /usr/local/bin/update-mtproxy-config.sh << 'EOF'
#!/bin/bash
curl -s https://core.telegram.org/getProxyConfig -o /etc/telegram/proxy-multi.conf
systemctl restart mtproto-proxy mtproto-proxy-2
EOF

chmod +x /usr/local/bin/update-mtproxy-config.sh

# Добавляем в cron (ежедневно в 3:00)
echo "0 3 * * * /usr/local/bin/update-mtproxy-config.sh" >> /etc/crontab
