#!/bin/bash

echo "========================================="
echo "  Диагностика и запуск MTProxy"
echo "========================================="

# 1. Проверяем, где бинарник
echo "🔍 Поиск бинарника..."
BINARY=$(find /root -name mtproto-proxy -type f -executable 2>/dev/null | head -1)

if [ -z "$BINARY" ]; then
    echo "❌ Бинарник не найден!"
    echo "Ищем в стандартных местах:"
    ls -la /usr/local/bin/mtproto-proxy 2>/dev/null || echo "Нет в /usr/local/bin"
    ls -la /root/MTProxy/objs/bin/mtproto-proxy 2>/dev/null || echo "Нет в /root/MTProxy/objs/bin"
    ls -la /root/MTProtoProxy/obj/bin/mtproto-proxy 2>/dev/null || echo "Нет в /root/MTProtoProxy/obj/bin"
    exit 1
fi

echo "✅ Найден бинарник: $BINARY"
BINARY_DIR=$(dirname "$BINARY")
echo "✅ Директория: $BINARY_DIR"

# 2. Проверяем конфиги
echo ""
echo "📁 Проверка конфигов:"
ls -la /etc/telegram/

# 3. Создаём пользователя (если нет)
if ! id -u mtproxy 2>/dev/null; then
    useradd -r -s /bin/false mtproxy
fi

# 4. Создаём правильный systemd сервис (без WorkingDirectory)
echo ""
echo "📝 Создание systemd сервиса..."

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

# 5. Копируем бинарник в /usr/local/bin
echo ""
echo "📦 Копирование бинарника..."
cp "$BINARY" /usr/local/bin/mtproto-proxy
chmod +x /usr/local/bin/mtproto-proxy
chown mtproxy:mtproxy /usr/local/bin/mtproto-proxy

# 6. Запускаем вручную для проверки
echo ""
echo "🧪 Запуск вручную (для диагностики):"
echo "========================================="
sudo -u mtproxy /usr/local/bin/mtproto-proxy \
    -u mtproxy \
    -p 8888 \
    -H 443 \
    -S ee7765622e796f74612e72755b744f13 \
    -P 8b654af431191c0e4f9e64c44f0d3d1e \
    --aes-pwd /etc/telegram/proxy-secret /etc/telegram/proxy-multi.conf \
    -M 2 &
sleep 3

# 7. Проверяем, запустился ли
echo ""
echo "🔍 Проверка процесса:"
ps aux | grep mtproto-proxy | grep -v grep

echo ""
echo "🔌 Проверка портов:"
ss -tlnp | grep -E "443|8443|8888|8889"

# 8. Если всё ок — запускаем через systemd
echo ""
echo "🚀 Запуск через systemd..."
systemctl daemon-reload
systemctl stop mtproto-proxy mtproto-proxy-2 2>/dev/null || true
systemctl start mtproto-proxy
systemctl start mtproto-proxy-2

echo ""
echo "📊 Статус:"
sleep 2
systemctl status mtproto-proxy --no-pager
echo ""
systemctl status mtproto-proxy-2 --no-pager

# 9. Логи
echo ""
echo "📋 Логи:"
journalctl -u mtproto-proxy -n 20 --no-pager

echo ""
echo "========================================="
echo "✅ Готово!"
echo "========================================="
echo "📱 Ссылки:"
echo "   tg://proxy?server=185.229.66.115&port=443&secret=ee7765622e796f74612e72755b744f13"
echo "   tg://proxy?server=185.229.66.115&port=8443&secret=c741a811908c5b4238dee60fc14c784c"
