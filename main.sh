
docker stop tg-proxy && docker rm tg-proxy

cat > /etc/mtg-proxy/config.toml <<'EOF'
secret = "eec741a811908c5b4238dee60fc14c784c7765622e796f74612e7275"
bind-to = "0.0.0.0:8443"
ad-tag = "b62807b6682914bcbd6ef432b20b89f4"
public-ipv4 = "185.229.66.115"
allow-fallback-on-unknown-dc = true
auto-update = true
EOF

docker run -d \
  --name tg-proxy \
  --restart=always \
  -p 8443:8443 \
  --add-host=web.yota.ru:185.229.66.115 \
  -v /etc/mtg-proxy:/config:ro \
  ghcr.io/mhsanaei/mtg-multi:latest \
  run /config/config.toml
