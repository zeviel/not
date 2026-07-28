#!/bin/bash

set -e  # Останавливаем скрипт при ошибке

echo "========================================="
echo "  Установка MTProxy (без Docker)"
echo "========================================="

# 1. Останавливаем и удаляем старые Docker-контейнеры (если есть)
echo "🧹 Очистка старых контейнеров..."
docker stop mtproto-proxy mtproto-proxy-2 2>/dev/null || true
docker rm mtproto-proxy mtproto-proxy-2 2>/dev/null || true

# 2. Удаляем Docker (опционально)
echo "🗑️  Удаление Docker..."
sudo apt remove -y docker* 2>/dev/null || true
sudo apt autoremove -y 2>/dev/null || true

# 3. Устанавливаем зависимости для сборки
echo "📦 Установка зависимостей..."
apt update
apt install -y git curl build-essential libssl-dev zlib1g-dev

# 4. Клонируем репозиторий и собираем бинарник
echo "🔨 Сборка MTProxy..."
if [ -d "MTProxy" ]; then
    rm -rf MTProxy
fi
git clone https://github.com/TelegramMessenger/MTProxy
cd MTProxy
make

# 5. Определяем правильный путь к бинарнику
echo "🔍 Поиск бинарника..."
# Ищем в objs/bin (правильный путь)
BINARY_PATH=$(find /root/MTProxy -type f -name mtproto-proxy -executable 2>/dev/null | head -1)

if [ -z "$BINARY_PATH" ]; then
    # Если не нашли, ищем в obj/bin (ошибочный путь из логов)
    BINARY_PATH=$(find /root/MTProxy -type f -name mtproto-proxy 2>/dev/null | head -1)
fi

if [ -z "$BINARY_PATH" ]; then
    echo "❌ Ошибка: бинарник mtproto-proxy не найден!"
    echo "Проверьте, что сборка завершилась успешно:"
    ls -la /root/MTProxy/*/bin/ 2>/dev/null || echo "Папка bin не найдена"
    exit 1
fi

BINARY_DIR=$(dirname "$BINARY_PATH")
echo "✅ Бинарник найден: $BINARY_PATH"
echo "✅ Рабочая директория: $BINARY_DIR"

# 6. Создаём папку для конфигов
echo "📁 Создание папки для конфигов..."
mkdir -p /etc/telegram

# 7. Скачиваем конфигурационные файлы
echo "📥 Загрузка конфигураций..."
curl -s https://core.telegram.org/getProxySecret -o /etc/telegram/proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o /etc/telegram/proxy-multi.conf

# Проверяем, что файлы скачались
if [[ ! -s /etc/telegram/proxy-secret ]] || [[ ! -s /etc/telegram/proxy-multi.conf ]]; then
    echo "❌ Ошибка: не удалось загрузить конфигурационные файлы!"
    exit 1
fi
echo "✅ Конфигурации загружены"

# 8. Настраиваем системные лимиты
echo "⚙️  Настройка системных лимитов..."
if ! grep -q "fs.file-max = 2097152" /etc/sysctl.conf; then
    echo "fs.file-max = 2097152" >> /etc/sysctl.conf
fi
sysctl -p

# Добавляем лимиты для пользователя nobody
if ! grep -q "nobody soft nofile" /etc/security/limits.conf; then
    echo "nobody soft nofile 65536" >> /etc/security/limits.conf
    echo "nobody hard nofile 65536" >> /etc/security/limits.conf
fi

# Для текущей сессии
ulimit -n 65536 2>/dev/null || true

# 9. Останавливаем старые сервисы (если есть)
echo "⏹️  Остановка старых сервисов..."
systemctl stop mtproto-proxy mtproto-proxy-2 2>/dev/null || true
systemctl disable mtproto-proxy mtproto-proxy-2 2>/dev/null || true

# 10. Создаём systemd сервисы
echo "📝 Создание systemd сервисов..."

# Первый прокси (порт 443)
cat > /etc/systemd/system/mtproto-proxy.service << EOF
[Unit]
Description=MTProto Proxy
After=network.target

[Service]
Type=simple
WorkingDirectory=${BINARY_DIR}
ExecStart=${BINARY_PATH} \\
    -u nobody \\
    -p 8888 \\
    -H 443 \\
    -S ee7765622e796f74612e72755b744f13 \\
    -P 8b654af431191c0e4f9e64c44f0d3d1e \\
    --aes-pwd /etc/telegram/proxy-secret /etc/telegram/proxy-multi.conf \\
    -M 2
Restart=on-failure
RestartSec=10
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF

# Второй прокси (порт 8443)
cat > /etc/systemd/system/mtproto-proxy-2.service << EOF
[Unit]
Description=MTProto Proxy 2 (port 8443)
After=network.target

[Service]
Type=simple
WorkingDirectory=${BINARY_DIR}
ExecStart=${BINARY_PATH} \\
    -u nobody \\
    -p 8889 \\
    -H 8443 \\
    -S c741a811908c5b4238dee60fc14c784c \\
    -P b62807b6682914bcbd6ef432b20b89f4 \\
    --aes-pwd /etc/telegram/proxy-secret /etc/telegram/proxy-multi.conf \\
    -M 2
Restart=on-failure
RestartSec=10
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF

echo "✅ systemd сервисы созданы"

# 11. Проверяем права на бинарник
echo "🔒 Проверка прав..."
chmod +x "${BINARY_PATH}"
chown nobody:nogroup "${BINARY_PATH}" 2>/dev/null || true

# 12. Запускаем прокси
echo "🚀 Запуск прокси..."
systemctl daemon-reload

# Запускаем первый прокси
systemctl start mtproto-proxy
systemctl enable mtproto-proxy

# Запускаем второй прокси
systemctl start mtproto-proxy-2
systemctl enable mtproto-proxy-2

# 13. Проверяем статус
echo "========================================="
echo "📊 Статус прокси:"
echo "========================================="
sleep 3

systemctl status mtproto-proxy --no-pager || true
echo ""
systemctl status mtproto-proxy-2 --no-pager || true

# 14. Если всё равно ошибка, пробуем без WorkingDirectory
if systemctl is-active --quiet mtproto-proxy; then
    echo "✅ Прокси запущены успешно!"
else
    echo "⚠️  Прокси не запустились. Пробуем альтернативный вариант..."
    
    # Альтернативный вариант без WorkingDirectory
    cat > /etc/systemd/system/mtproto-proxy.service << EOF
[Unit]
Description=MTProto Proxy
After=network.target

[Service]
Type=simple
ExecStart=${BINARY_PATH} \\
    -u nobody \\
    -p 8888 \\
    -H 443 \\
    -S ee7765622e796f74612e72755b744f13 \\
    -P 8b654af431191c0e4f9e64c44f0d3d1e \\
    --aes-pwd /etc/telegram/proxy-secret /etc/telegram/proxy-multi.conf \\
    -M 2
Restart=on-failure
RestartSec=10
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF

    cat > /etc/systemd/system/mtproto-proxy-2.service << EOF
[Unit]
Description=MTProto Proxy 2 (port 8443)
After=network.target

[Service]
Type=simple
ExecStart=${BINARY_PATH} \\
    -u nobody \\
    -p 8889 \\
    -H 8443 \\
    -S c741a811908c5b4238dee60fc14c784c \\
    -P b62807b6682914bcbd6ef432b20b89f4 \\
    --aes-pwd /etc/telegram/proxy-secret /etc/telegram/proxy-multi.conf \\
    -M 2
Restart=on-failure
RestartSec=10
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl restart mtproto-proxy mtproto-proxy-2
    
    echo "🔄 Альтернативная конфигурация применена"
fi

# 15. Показываем логи
echo "========================================="
echo "📋 Логи первого прокси:"
echo "========================================="
journalctl -u mtproto-proxy -n 10 --no-pager || true

echo "========================================="
echo "📋 Логи второго прокси:"
echo "========================================="
journalctl -u mtproto-proxy-2 -n 10 --no-pager || true

# 16. Проверяем порты
echo "========================================="
echo "🔌 Проверка портов:"
echo "========================================="
ss -tlnp | grep -E "443|8443|8888|8889" || echo "⚠️  Порты не найдены"

# 17. Проверяем статистику
echo "========================================="
echo "📊 Статистика:"
echo "========================================="
sleep 2
curl -s http://localhost:8888/stats 2>/dev/null || echo "⚠️  Статистика недоступна"
echo ""
curl -s http://localhost:8889/stats 2>/dev/null || echo "⚠️  Статистика недоступна"

# 18. Настраиваем ежедневное обновление конфига
echo "🔄 Настройка ежедневного обновления конфига..."
cat > /usr/local/bin/update-mtproxy-config.sh << 'EOF'
#!/bin/bash
curl -s https://core.telegram.org/getProxyConfig -o /etc/telegram/proxy-multi.conf
systemctl restart mtproto-proxy mtproto-proxy-2
EOF

chmod +x /usr/local/bin/update-mtproxy-config.sh

# Добавляем в cron, если ещё не добавлено
if ! crontab -l 2>/dev/null | grep -q "update-mtproxy-config"; then
    (crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/update-mtproxy-config.sh") | crontab -
fi

# 19. Выводим итоговую информацию
echo "========================================="
echo "✅ Установка завершена!"
echo "========================================="
echo ""
echo "📱 Ссылки для подключения:"
echo "   tg://proxy?server=185.229.66.115&port=443&secret=ee7765622e796f74612e72755b744f13"
echo "   tg://proxy?server=185.229.66.115&port=8443&secret=c741a811908c5b4238dee60fc14c784c"
echo ""
echo "📊 Статистика:"
echo "   curl http://localhost:8888/stats"
echo "   curl http://localhost:8889/stats"
echo ""
echo "📋 Логи:"
echo "   journalctl -u mtproto-proxy -f"
echo "   journalctl -u mtproto-proxy-2 -f"
echo ""
echo "🔄 Управление:"
echo "   systemctl restart mtproto-proxy"
echo "   systemctl restart mtproto-proxy-2"
echo "========================================="

# 20. Проверяем, что процессы действительно работают
echo ""
echo "🔍 Проверка работающих процессов:"
ps aux | grep mtproto-proxy | grep -v grep || echo "⚠️  Процессы не найдены!"
