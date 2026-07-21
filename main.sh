docker rm -f mtproto-proxy-8443 2>/dev/null || true && \
sudo docker run -d \
  --name="mtproto-proxy-8443" \
  --restart=always \
  -p "8443:3128" \
  nineseconds/mtg:1 \
  run \
  -4 "185.229.66.115:8443" \
  "eec741a811908c5b4238dee60fc14c784c7765622e796f74612e7275" \
  "b62807b6682914bcbd6ef432b20b89f4"
