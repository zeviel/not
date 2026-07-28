# Временно (до перезагрузки)
ulimit -n 65535

# Постоянно — отредактируйте /etc/security/limits.conf
echo "root soft nofile 65535" >> /etc/security/limits.conf
echo "root hard nofile 65535" >> /etc/security/limits.conf
sudo docker run -d \
  --name=mtproto-proxy \
  --restart=unless-stopped \
  -p 443:443 \
  -v proxy-config:/data \
  -e SECRET=ee7765622e796f74612e72755b744f13 \
  -e TAG=8b65a4af31191c0e4f9e64c44f0d3d1e \
  telegrammessenger/proxy > /dev/null 2>&1
  
sudo docker run -d \
  --name=mtproto-proxy-2 \
  --restart=unless-stopped \
  -p 8443:443 \
  -v proxy-config:/data \
  -e SECRET=c741a811908c5b4238dee60fc14c784c \
  -e TAG=b62807b6682914bcbd6ef432b20b89f4 \
  telegrammessenger/proxy > /dev/null 2>&1
