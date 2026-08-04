docker rm -f tg-proxy

docker run -d --restart=always --name tg-proxy \
  -p 8443:443 \
  --privileged \
  --ulimit nofile=65535:65535 \
  -v /etc/telemt-config:/config \
  telegrammessenger/proxy:latest
