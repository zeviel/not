#!/bin/bash

set -e

echo "========================================="
echo "  Установка MTProxy (бинарный файл)"
echo "========================================="

# 1. Устанавливаем зависимости для сборки
echo "📦 Установка зависимостей..."
apt update
apt install -y git curl build-essential libssl-dev zlib1g-dev

# 2. Клонируем и собираем
echo "🔨 Сборка MTProxy..."
cd /root
rm -rf MTProxy
git clone https://github.com/TelegramMessenger/MTProxy
cd MTProxy

# Чистая сборка
make clean 2>/dev/null || true
make

# 3. Проверяем бинарник
if [ -f "objs/bin/mtproto-proxy" ]; then
    BINARY_PATH="/root/MTProxy/objs/bin/mtproto-proxy"
else
    echo "❌ Бинарник не найден!"
    exit 1
fi

echo "✅ Бинарник: $BINARY_PATH"

# 4. Копируем в /usr/local/bin
cp "$BINARY_PATH" /usr/local/bin/mtproto-proxy
chmod +x /usr/local/bin/mtproto-proxy

# 5. Создаём пользователя
echo "👤 Создание пользователя..."
if ! id -u mtproxy 2>/dev/null; then
    useradd -r -s /bin/false mtproxy
fi

# 6. Создаём папку для конфигов
mkdir -p /etc/telegram

# 7. Скачиваем конфигурации
echo "📥 Загрузка конфигураций..."
curl -s https://core.telegram.org/getProxySecret -o /etc/telegram/proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o /etc/telegram/proxy-multi.conf

# 8. Настраиваем лимиты
echo "⚙️  Настройка лимитов..."
echo "fs.file-max = 2097152" >> /etc/sysctl.conf
sysctl -p

echo "mtproxy soft nofile 65536" >> /etc/security/limits.conf
echo "mtproxy hard nofile 65536" >> /etc/security/limits.conf

# 9. Создаём systemd сервисы
echo "📝 Создание systemd сервисов..."

cat > /etc/systemd/system/mtproto-proxy.service << 'EOF'
[Unit]
Description=MTProto Proxy
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/mtproto-proxy \
    -u mtproxy \
    -p 8888 \
    -H 443 \
    -S ee7765622e796f74612e72755b744f13 \
    -P 8b654af431191c0e4f9e64c44f0d3d1e \
    --aes-pwd /etc/telegram/proxy-secret /etc/telegram/proxy-multi.conf \
    -M 2
Restart=on-failure
RestartSec=10
User=mtproxy
Group=mtproxy

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/mtproto-proxy-2.service << 'EOF'
[Unit]
Description=MTProto Proxy 2 (port 8443)
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/mtproto-proxy \
    -u mtproxy \
    -p 8889 \
    -H 8443 \
    -S c741a811908c5b4238dee60fc14c784c \
    -P b62807b6682914bcbd6ef432b20b89f4 \
    --aes-pwd /etc/telegram/proxy-secret /etc/telegram/proxy-multi.conf \
    -M 2
Restart=on-failure
RestartSec=10
User=mtproxy
Group=mtproxy

[Install]
WantedBy=multi-user.target
EOF

# 10. Запускаем
echo "🚀 Запуск прокси..."
systemctl daemon-reload
systemctl stop mtproto-proxy mtproto-proxy-2 2>/dev/null || true
systemctl start mtproto-proxy
systemctl enable mtproto-proxy
systemctl start mtproto-proxy-2
systemctl enable mtproto-proxy-2

# 11. Проверяем
echo ""
echo "📊 Статус:"
sleep 2
systemctl status mtproto-proxy --no-pager
echo ""
systemctl status mtproto-proxy-2 --no-pager

# 12. Логи
echo ""
echo "📋 Логи прокси 1:"
journalctl -u mtproto-proxy -n 20 --no-pager

echo ""
echo "📋 Логи прокси 2:"
journalctl -u mtproto-proxy-2 -n 20 --no-pager

# 13. Проверяем порты
echo ""
echo "🔌 Проверка портов:"
ss -tlnp | grep -E "443|8443|8888|8889"

# 14. Статистика
echo ""
echo "📊 Статистика:"
sleep 1
curl -s http://localhost:8888/stats || echo "⏳ Статистика ещё не готова"
echo ""
curl -s http://localhost:8889/stats || echo "⏳ Статистика ещё не готова"

# 15. Cron для обновления
echo ""
echo "🔄 Настройка автообновления..."
cat > /usr/local/bin/update-mtproxy-config.sh << 'EOF'
#!/bin/bash
curl -s https://core.telegram.org/getProxyConfig -o /etc/telegram/proxy-multi.conf
systemctl restart mtproto-proxy mtproto-proxy-2
EOF
chmod +x /usr/local/bin/update-mtproxy-config.sh

(crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/update-mtproxy-config.sh") | crontab -

echo ""
echo "========================================="
echo "✅ Установка завершена!"
echo "========================================="
echo ""
echo "📱 Ссылки для подключения:"
echo "   tg://proxy?server=185.229.66.115&port=443&secret=ee7765622e796f74612e72755b744f13"
echo "   tg://proxy?server=185.229.66.115&port=8443&secret=c741a811908c5b4238dee60fc14c784c"
echo ""
echo "📋 Команды управления:"
echo "   systemctl status mtproto-proxy"
echo "   systemctl restart mtproto-proxy"
echo "   journalctl -u mtproto-proxy -f"
echo ""
echo "📊 Статистика:"
echo "   curl http://localhost:8888/stats"
echo "   curl http://localhost:8889/stats"
echo "========================================="
