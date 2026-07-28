docker run -d \
    --name=mtproto-proxy \
    --restart=unless-stopped \
    -p 443:443 \
    -v proxy-config-443:/data \
    -e SECRET=ee7765622e796f74612e72755b744f13 \
    -e TAG=8b65a4af31191c0e4f9e64c44f0d3d1e \
    telegrammessenger/proxy:latest
