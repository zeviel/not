docker exec -it mtproto-proxy sh -c "ulimit -n"
docker exec -it mtproto-proxy-2 sh -c "ulimit -n"
docker rm -f mtproto-proxy
docker run -d \
  --name=mtproto-proxy \
  --restart=always \
  --ulimit nofile=65535:65535 \
  -p 443:443 \
  -v proxy-config:/data \
  -e SECRET=ee7765622e796f74612e72755b744f13 \
  -e TAG=8b65a4af31191c0e4f9e64c44f0d3d1e \
  telegrammessenger/proxy
  docker rm -f mtproto-proxy-2
docker run -d \
  --name=mtproto-proxy-2 \
  --restart=always \
  --ulimit nofile=65535:65535 \
  -p 8443:443 \
  -v proxy-config:/data \
  -e SECRET=c741a811908c5b4238dee60fc14c784c \
  -e TAG=b62807b6682914bcbd6ef432b20b89f4 \
  telegrammessenger/proxy
