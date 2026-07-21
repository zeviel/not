docker rm -f mtproto-proxy-8443 2>/dev/null


sudo docker run -d \
    --name=mtproto-proxy-8443 \
    --restart=always \
    -p 8443:443 \
    -e MTG_SECRET=ff9f8d0be0a0eddb9fa2ad8d4b1ec8b8 \
    -e MTG_AD_TAG="b73eb664e3dd95631c0b2112643d28d8" \
    -e MTG_BIND_TO="0.0.0.0:3128" \
    nineseconds/mtg:2
