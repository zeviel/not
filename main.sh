
docker rm -f mtproto-proxy-8443

# 2. Запускаем заново с правильным синтаксисом аргументов
sudo docker run -d \
    --name="mtproto-proxy-8443" \
    --restart=always \
    -p "8443:3128" \
    -v "/etc/mtg-proxy:/config:ro" \
    nineseconds/mtg:2 \
    run /config/config.toml
