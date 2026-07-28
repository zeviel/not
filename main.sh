docker run -d -p 443:443 --name=mtproto-proxy --restart=always \
  -e SECRET=ee7765622e796f74612e72755b744f13 \
  -e TAG=8b65a4af31191c0e4f9e64c44f0d3d1e \
  telegrammessenger/proxy:latest

