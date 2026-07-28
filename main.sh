#!/bin/bash

set -e

echo "========================================="
echo "  Установка MTProxy (без сборки)"
echo "========================================="

# 1. Останавливаем и удаляем старые контейнеры
echo "🧹 Очистка..."
docker stop mtproto-proxy mtproto-proxy-2 2>/dev/null || true
docker rm mtproto-proxy mtproto-proxy-2 2>/dev/null || true

# 2. Удаляем старую папку с исходниками и скачиваем заново
echo "🗑️  Удаление старых исходников..."
cd /root
rm -rf MTProxy

# 3. Клонируем репозиторий
echo "📥 Клонирование репозитория..."
git clone https://github.com/TelegramMessenger/MTProxy
cd MTProxy

# 4. Делаем make clean перед сборкой
echo "🧹 Clean..."
make clean 2>/dev/null || true

# 5. Собираем с явными флагами
echo "🔨 Сборка..."
make CFLAGS="-O3 -std=gnu11 -Wall -Wno-array-bounds"

# 6. Проверяем, что бинарник создался
echo "🔍 Проверка бинарника..."
if [ -f "objs/bin/mtproto-proxy" ]; then
    BINARY_PATH="/root/MTProxy/objs/bin/mtproto-proxy"
elif [ -f "bin/mtproto-proxy" ]; then
    BINARY_PATH="/root/MTProxy/bin/mtproto-proxy"
else
    echo "❌ Бинарник не найден!"
    echo "Содержимое папки objs/bin:"
    ls -la objs/bin/ 2>/dev/null || echo "Папка objs/bin не существует"
    echo "Содержимое папки bin:"
    ls -la bin/ 2>/dev/null || echo "Папка bin не существует"
    exit 1
fi

echo "✅ Бинарник найден: $BINARY_PATH"

# 7. Создаём папку для конфигов
echo "📁 Создание папки для конфигов..."
mkdir -p /etc/telegram

# 8. Скачиваем конфигурационные файлы
echo "📥 Загрузка конфигураций..."
curl -s https://core.telegram.org/getProxySecret -o /etc/telegram/proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o /etc/telegram/proxy-multi.conf

# Проверяем загрузку
if [[ ! -s /etc/telegram/proxy-secret ]] || [[ ! -s /etc/telegram/proxy-multi.conf ]]; then
    echo "❌ Ошибка загрузки конфигураций!"
    exit 1
fi

echo "✅ Конфигурации загружены"

# 9. Создаём пользователя для прокси (если не существует)
echo "👤 Создание пользователя..."
if ! id -u mtproxy 2>/dev/null; then
    useradd -r -s /bin/false mtproxy
fi

# 10. Копируем бинарник в /usr/local/bin
echo "📦 Установка бинарника..."
cp "$BINARY_PATH" /usr/local/bin/mtproto-proxy
chmod +x /usr/local/bin/mtproto-proxy

# 11. Настраиваем системные лимиты
echo "⚙️  Настройка лимитов..."
if ! grep -q "fs.file-max = 2097152" /etc/sysctl.conf; then
    echo "fs.file-max = 2097152" >> /etc/sysctl.conf
fi
sysctl -p

if ! grep -q "mtproxy soft nofile" /etc/security/limits.conf; then
    echo "mtproxy soft nofile 65536" >> /etc/security/limits.conf
    echo "mtproxy hard nofile 65536" >> /etc/security/limits.conf
fi

# 12. Создаём systemd сервисы
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

echo "✅ systemd сервисы созданы"

# 13. Запускаем
echo "🚀 Запуск прокси..."
systemctl daemon-reload
systemctl stop mtproto-proxy mtproto-proxy-2 2>/dev/null || true
systemctl start mtproto-proxy
systemctl enable mtproto-proxy
systemctl start mtproto-proxy-2
systemctl enable mtproto-proxy-2

# 14. Проверяем
echo "========================================="
echo "📊 Проверка статуса:"
echo "========================================="
sleep 2
systemctl status mtproto-proxy --no-pager || true
echo ""
systemctl status mtproto-proxy-2 --no-pager || true

# 15. Показываем логи
echo "========================================="
echo "📋 Логи:"
echo "========================================="
journalctl -u mtproto-proxy -n 15 --no-pager || true

# 16. Проверяем порты
echo "========================================="
echo "🔌 Порты:"
echo "========================================="
ss -tlnp | grep -E "443|8443|8888|8889" || echo "⚠️  Порты не найдены"

# 17. Статистика
echo "========================================="
echo "📊 Статистика:"
echo "========================================="
sleep 1
curl -s http://localhost:8888/stats 2>/dev/null || echo "⚠️  Статистика недоступна"
echo ""
curl -s http://localhost:8889/stats 2>/dev/null || echo "⚠️  Статистика недоступна"

# 18. Cron для обновления конфига
echo "🔄 Настройка автообновления..."
cat > /usr/local/bin/update-mtproxy-config.sh << 'EOF'
#!/bin/bash
curl -s https://core.telegram.org/getProxyConfig -o /etc/telegram/proxy-multi.conf
systemctl restart mtproto-proxy mtproto-proxy-2
EOF
chmod +x /usr/local/bin/update-mtproxy-config.sh

if ! crontab -l 2>/dev/null | grep -q "update-mtproxy-config"; then
    (crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/update-mtproxy-config.sh") | crontab -
fi

# 19. Итог
echo "========================================="
echo "✅ Установка завершена!"
echo "========================================="
echo ""
echo "📱 Ссылки для подключения:"
echo "   tg://proxy?server=185.229.66.115&port=443&secret=ee7765622e796f74612e72755b744f13"
echo "   tg://proxy?server=185.229.66.115&port=8443&secret=c741a811908c5b4238dee60fc14c784c"
echo ""
echo "📋 Логи:"
echo "   journalctl -u mtproto-proxy -f"
echo "   journalctl -u mtproto-proxy-2 -f"
echo "========================================="
