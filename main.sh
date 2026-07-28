#!/bin/bash

echo "========================================="
echo "  Запуск MTProxy (исправление прав)"
echo "========================================="

# 1. Убиваем старые процессы
echo "🧹 Очистка..."
pkill -f mtproto-proxy 2>/dev/null || true
systemctl stop mtproto-proxy mtproto-proxy-2 2>/dev/null || true

# 2. Проверяем, что порты свободны
echo "🔌 Проверка портов..."
ss -tlnp | grep -E "443|8443" || echo "Порты свободны"

# 3. Запускаем от root (но с опцией -u nobody для понижения привилегий)
echo "🚀 Запуск прокси 1 (порт 443)..."
nohup /usr/local/bin/mtproto-proxy \
    -u nobody \
    -p 8888 \
    -H 443 \
    -S ee7765622e796f74612e72755b744f13 \
    -P 8b654af431191c0e4f9e64c44f0d3d1e \
    --aes-pwd /etc/telegram/proxy-secret /etc/telegram/proxy-multi.conf \
    -M 2 \
    >> /var/log/mtproto-proxy.log 2>&1 &

echo "🚀 Запуск прокси 2 (порт 8443)..."
nohup /usr/local/bin/mtproto-proxy \
    -u nobody \
    -p 8889 \
    -H 8443 \
    -S c741a811908c5b4238dee60fc14c784c \
    -P b62807b6682914bcbd6ef432b20b89f4 \
    --aes-pwd /etc/telegram/proxy-secret /etc/telegram/proxy-multi.conf \
    -M 2 \
    >> /var/log/mtproto-proxy-2.log 2>&1 &

# 4. Ждём и проверяем
echo "⏳ Ожидание запуска..."
sleep 3

echo ""
echo "📊 Проверка процессов:"
ps aux | grep mtproto-proxy | grep -v grep

echo ""
echo "🔌 Проверка портов:"
ss -tlnp | grep -E "443|8443|8888|8889"

echo ""
echo "📋 Логи:"
tail -20 /var/log/mtproto-proxy.log

echo ""
echo "📊 Статистика:"
curl -s http://localhost:8888/stats || echo "⏳ Статистика ещё не готова"

echo ""
echo "========================================="
echo "✅ Готово!"
echo "========================================="
