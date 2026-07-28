docker rm -f mtproto-proxy mtproto-proxy-2 2>/dev/null || true

docker run -d \
  --name=mtproto-proxy \
  --restart=always \
  -p 443:443 \
  -e SECRET=ee7765622e796f74612e72755b744f13 \
  -e TAG=8b65a4af31191c0e4f9e64c44f0d3d1e \
  telegrammessenger/proxy:latest \
  /bin/bash -c "exec /objs/bin/mtproto-proxy -u nobody -p 8888 -H 443 -S ee7765622e796f74612e72755b744f13 -P 8b65a4af31191c0e4f9e64c44f0d3d1e --aes-pwd /data/proxy-secret /data/proxy-multi.conf -M 1"

docker run -d \
  --name=mtproto-proxy-2 \
  --restart=always \
  -p 8443:443 \
  -e SECRET=c741a811908c5b4238dee60fc14c784c \
  -e TAG=b62807b6682914bcbd6ef432b20b89f4 \
  telegrammessenger/proxy:latest \
  /bin/bash -c "exec /objs/bin/mtproto-proxy -u nobody -p 8888 -H 443 -S c741a811908c5b4238dee60fc14c784c -P b62807b6682914bcbd6ef432b20b89f4 --aes-pwd /data/proxy-secret /data/proxy-multi.conf -M 1"
