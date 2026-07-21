docker stop mtproto-proxy-8443 && docker rm mtproto-proxy-8443

# Сгенерировать секрет с web.yota.ru
SECRET=$(docker run --rm nineseconds/mtg:2 generate-secret web.yota.ru)

sudo tee /etc/mtg-proxy/config.toml > /dev/null <<EOF
secret = "${SECRET}"
bind-to = "0.0.0.0:3128"
ad-tag = "b73eb664e3dd95631c0b2112643d28d8"
EOF

sudo docker run -d \
    --name=mtproto-proxy-8443 \
    --restart=always \
    -p 8443:3128 \
    -v /etc/mtg-proxy:/config \
    nineseconds/mtg:2 \
    run /config/config.toml
