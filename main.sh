docker rm -f mtproto-proxy-8443
sudo tee /etc/mtg-proxy/config.toml > /dev/null <<EOF
[[secret]]
secret = "eec741a811908c5b4238dee60fc14c784c7765622e796f74612e7275"
ad-tag = "b62807b6682914bcbd6ef432b20b89f4"

bind-to = "0.0.0.0:3128"
EOF

cat /etc/mtg-proxy/config.toml
sudo docker run -d \
    --name="mtproto-proxy-8443" \
    --restart=always \
    -p "8443:3128" \
    -v "/etc/mtg-proxy:/config:ro" \
    devgsc/mtg-multi:latest \
    run /config/config.toml
