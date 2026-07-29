docker stop tg-proxy && docker rm tg-proxy

docker run -d \
  --name tg-proxy \
  --restart=always \
  -p 8443:8443 \
  -v /etc/mtg-proxy:/config:ro \
  nineseconds/mtg:latest \
  run /config/config.toml
