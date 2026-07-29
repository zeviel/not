docker stop tg-proxy && docker rm tg-proxy
docker run -d \
  --name tg-proxy \
  --restart=always \
  -p 8443:8443 \
  -v /etc/mtg-proxy:/config:ro \
  ghcr.io/mhsanaei/mtg-multi:latest run /config/config.toml
