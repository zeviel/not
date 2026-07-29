docker stop tg-proxy && docker rm tg-proxy

docker run -d \
  --name tg-proxy \
  --restart=always \
  -p 8443:8443 \
  nineseconds/mtg:2 \
  run -t "eec741a811908c5b4238dee60fc14c784c7765622e796f74612e7275" \
  -a "185.229.66.115:8443" \
  --adtag "b62807b6682914bcbd6ef432b20b89f4"
