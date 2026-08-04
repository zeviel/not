docker stop tg-proxy && docker rm tg-proxy

docker run -d \
  --name tg-proxy \
  --restart=always \
  -p 8443:3128 \
  nineseconds/mtg:1 \
  run --ip 185.229.66.115 eec741a811908c5b4238dee60fc14c784c7765622e796f74612e7275 b62807b6682914bcbd6ef432b20b89f4
