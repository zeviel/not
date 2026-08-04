# Удаляем сломанный контейнер
docker rm -f tg-proxy

# Перезаписываем /etc/telemt-config/config.toml в формате Telegram MTProxy
cat > /etc/telemt-config/config.toml << 'EOF'
# Порт, на котором работает прокси (внутри контейнера)
port = 443

# Полный секрет (64 символа). Здесь указан ee + ваш ключ + hex домена web.yota.ru
secret = "eec741a811908c5b4238dee60fc14c784c7765622e796f74612e7275"

# Ваш тег для статистики
tag = "b62807b6682914bcbde6f432b20b89f4"

# Настройки производительности
workers = 4
# Количество попыток подключения к Telegram
upstream_retries = 2
# Время ожидания подключения к Telegram (в секундах)
upstream_timeout = 15

# Необязательно, для сбора статистики
# stats_port = 9091
EOF

# Запускаем официальный контейнер правильно
docker run -d --restart=always --name tg-proxy \
  -p 8443:443 \
  -v /etc/telemt-config:/config \
  telegrammessenger/proxy:latest
