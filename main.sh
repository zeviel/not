docker rm -f tg-proxy
apt-get update && apt-get install -y git curl build-essential libssl-dev zlib1g-dev
git clone https://github.com/TelegramMessenger/MTProxy
cd MTProxy
make && cd objs/bin
curl -s https://core.telegram.org/getProxySecret -o proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf
cd objs/bin && ./mtproto-proxy -u nobody -p 8888 -H 8443 \
  -S c741a811908c5b4238dee60fc14c784c \
  -P b62807b6682914bcbd6ef432b20b89f4 \
  --aes-pwd proxy-secret proxy-multi.conf -M 1 &
