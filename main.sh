docker stop mtproto-proxy-8443 && docker rm mtproto-proxy-8443

sudo mkdir -p /etc/mtg-proxy
sudo tee /etc/mtg-proxy/config.toml > /dev/null <<EOF
secret = "eec741a811908c5b4238dee60fc14c784c7765622e796f74612e7275"
bind-to = "0.0.0.0:443"
ad-tag = "b62807b6682914bcbd6ef432b20b89f4"
public-ipv4 = "185.229.66.115"
EOF

docker run -d \
  --name mtproto-proxy-8443 \
  --restart=always \
  -p 8443:443 \
  -v "/etc/mtg-proxy:/config:ro" \
  ghcr.io/mhsanaei/mtg-multi:latest \
  run /config/config.toml
