# Останавливаем старый
docker stop tg-proxy && docker rm -f tg-proxy

# Создаем новый конфиг с allow_any_sni
cat > /etc/telemt-config/config.toml << 'EOF'
proxy_port = 443
secret = "eec741a811908c5b4238dee60fc14c784c7765622e796f74612e7275"
tag = "b62807b6682914bcbde6f432b20b89f4"

[fake_tls]
enabled = true
allowed_snis = ["web.yota.ru"]

[upstream]
timeout_secs = 10
retries = 3
connect_timeout = 5

workers = 4
keepalive = 300
log_level = "info"
EOF

# Запускаем заново
sudo docker run -d --name tg-proxy \
  --ulimit nofile=65536:65536 \
  --privileged \
  --restart=always \
  -p 8443:443 \
  -v /etc/telemt-config:/etc/telemt \
  whn0thacked/telemt-docker:latest \
  telemt /etc/telemt/config.toml
