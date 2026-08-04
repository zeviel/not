docker stop tg-proxy && docker rm tg-proxy

docker run -d \
  --name tg-proxy \
  --restart=always \
  -p 8443:3128 \
  -v /etc/mtg-proxy/config.toml:/config.toml:ro \
  nineseconds/mtg:1
