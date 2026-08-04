# Остановите контейнер
docker stop tg-proxy && docker rm -f tg-proxy

cat > /etc/config/config.toml << 'EOF'
# Основные настройки
proxy_port = 443
secret = "c741a811908c5b4238dee60fc14c784c"
tag = "b62807b6682914bcbde6f432b20b89f4"

# ВКЛЮЧАЕМ Fake TLS
[fake_tls]
enabled = true
# Разрешаем конкретный SNI (ваш!)
allowed_snis = ["web.yota.ru"]
# Или разрешить все SNI (менее безопасно):
# allow_any_sni = true

# Альтернатива: если используете ssl_cert
# ssl_cert = "/path/to/cert.pem"
# ssl_key = "/path/to/key.pem"

# Настройки подключения к Telegram
[upstream]
timeout_secs = 10
retries = 3
connect_timeout = 5

# Производительность
workers = 4
keepalive = 300

# Логирование (можно поставить debug для отладки)
log_level = "info"
EOF

sudo docker run -d --name tg-proxy \
  --ulimit nofile=65536:65536 \
  --privileged \
  --restart=always \
  -p 8443:443 \
  -v /etc/mtg-proxy/:/config:ro \
  whn0thacked/telemt-docker:latest \
  telemt /etc/config/config.toml
