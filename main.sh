docker rm -f tg-proxy
docker run -d -p 8443:443 --name=tg-proxy --restart=always \
  -e SECRET=c741a811908c5b4238dee60fc14c784c \
  -e TAG=b62807b6682914bcbd6ef432b20b89f4 \
  telegrammessenger/proxy:latest \
  /bin/bash -c "sed -i 's/maxconns 60000/maxconns 2000/g' /run.sh && /run.sh"
