docker rm -f mtproto-proxy-8443 2>/dev/null

sudo docker run -d --name=mtproto-proxy-8443 --restart=always -p 0.0.0.0:8443:8443 -e MPROXY_PORT=8443 -v proxy-config-8443:/data -e SECRET=ff9f8d0be0a0eddb9fa2ad8d4b1ec8b8 -e TAG="b73eb664e3dd95631c0b2112643d32d8" telegrammessenger/proxy:latest
