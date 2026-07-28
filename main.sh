#!/bin/bash

echo "========================================="
echo "  Установка MTProxy (статическая сборка)"
echo "========================================="

# 1. Скачиваем статическую сборку
echo "📥 Скачивание статической сборки..."
cd /root

# Скачиваем с официального репозитория (если есть)
if ! wget -O mtproto-proxy https://github.com/TelegramMessenger/MTProxy/releases/download/v2.0/mtproto-proxy-linux-amd64; then
    # Если нет, используем альтернативный источник
    echo "⚠️  Скачивание с основного репозитория не удалось, пробуем альтернативу..."
    wget -O mtproto-proxy https://core.telegram.org/getProxySecret/mtproto-proxy-linux-amd64 || {
        echo "❌ Не удалось скачать бинарник"
        exit 1
    }
fi

chmod +x mtproto-proxy

# 2. Создаём конфиги
mkdir -p /etc/telegram
curl -s https://core.telegram.org/getProxySecret -o /etc/telegram/proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o /etc/telegram/proxy-multi.conf

# 3. Запускаем через nohup для стабильности
echo "🚀 Запуск прокси..."

nohup /root/mtproto-proxy \
    -u nobody \
    -p 8888 \
    -H 443 \
    -S ee7765622e796f74612e72755b744f13 \
    -P 8b654af431191c0e4f9e64c44f0d3d1e \
    --aes-pwd /etc/telegram/proxy-secret /etc/telegram/proxy-multi.conf \
    -M 2 \
    > /var/log/mtproto-proxy.log 2>&1 &

nohup /root/mtproto-proxy \
    -u nobody \
    -p 8889 \
    -H 8443 \
    -S c741a811908c5b4238dee60fc14c784c \
    -P b62807b6682914bcbd6ef432b20b89f4 \
    --aes-pwd /etc/telegram/proxy-secret /etc/telegram/proxy-multi.conf \
    -M 2 \
    > /var/log/mtproto-proxy-2.log 2>&1 &

# 4. Проверяем
sleep 5
echo ""
echo "📊 Проверка:"
ps aux | grep mtproto-proxy | grep -v grep

echo ""
echo "🔌 Порты:"
ss -tlnp | grep -E "443|8443|8888|8889"

echo ""
echo "📋 Логи:"
tail -20 /var/log/mtproto-proxy.log

echo ""
echo "📊 Статистика:"
curl -s http://localhost:8888/stats

echo ""
echo "========================================="
echo "✅ Готово!"
echo "📱 tg://proxy?server=185.229.66.115&port=443&secret=ee7765622e796f74612e72755b744f13"
echo "📱 tg://proxy?server=185.229.66.115&port=8443&secret=c741a811908c5b4238dee60fc14c784c"
echo "========================================="
