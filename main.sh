#!/bin/bash

echo "========================================="
echo "  Запуск двух прокси (от root)"
echo "========================================="

# Убиваем всё лишнее
pkill -f mtproto-proxy 2>/dev/null || true
systemctl stop mtproto-proxy mtproto-proxy-2 2>/dev/null || true

# Создаём конфиги
mkdir -p /etc/telegram
curl -s https://core.telegram.org/getProxySecret -o /etc/telegram/proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o /etc/telegram/proxy-multi.conf

# Запускаем первый прокси (порт 443)
nohup /usr/local/bin/mtproto-proxy \
    -u nobody \
    -p 8888 \
    -H 443 \
    -S ee7765622e796f74612e72755b744f13 \
    -P 8b654af431191c0e4f9e64c44f0d3d1e \
    --aes-pwd /etc/telegram/proxy-secret /etc/telegram/proxy-multi.conf \
    -M 2 \
    > /var/log/mtproto-proxy.log 2>&1 &

# Запускаем второй прокси (порт 8443)
nohup /usr/local/bin/mtproto-proxy \
    -u nobody \
    -p 8889 \
    -H 8443 \
    -S c741a811908c5b4238dee60fc14c784c \
    -P b62807b6682914bcbd6ef432b20b89f4 \
    --aes-pwd /etc/telegram/proxy-secret /etc/telegram/proxy-multi.conf \
    -M 2 \
    > /var/log/mtproto-proxy-2.log 2>&1 &

# Проверяем
sleep 3
echo ""
echo "📊 Процессы:"
ps aux | grep mtproto-proxy | grep -v grep

echo ""
echo "🔌 Порты:"
ss -tlnp | grep -E "443|8443|8888|8889"

echo ""
echo "📋 Логи первого прокси:"
tail -5 /var/log/mtproto-proxy.log

echo ""
echo "📊 Статистика:"
curl -s http://localhost:8888/stats 2>/dev/null || echo "⏳ Статистика ещё не готова"

echo ""
echo "========================================="
echo "✅ Ваши прокси:"
echo "tg://proxy?server=185.229.66.115&port=443&secret=ee7765622e796f74612e72755b744f13"
echo "tg://proxy?server=185.229.66.115&port=8443&secret=c741a811908c5b4238dee60fc14c784c"
echo "========================================="
