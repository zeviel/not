# 1. Меняем рекламный токен в конфигурационном файле на сервере
sudo sed -i 's/ad-tag = .*/ad-tag = "b62807b6682914bcbd6ef432b20b89f4"/' /etc/mtg-proxy/config.toml
cat /etc/mtg-proxy/config.toml
# 2. Удаляем старый контейнер
docker rm -f mtproto-proxy-8443

# 3. Запускаем заново с обновленным конфигом
sudo docker run -d \
    --name="mtproto-proxy-8443" \
    --restart=always \
    -p "8443:3128" \
    -v "/etc/mtg-proxy:/config:ro" \
    nineseconds/mtg:2 \
    run /config/config.toml
