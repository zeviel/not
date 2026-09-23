apt-get -o DPkg::Lock::Timeout=600 update
apt-get -o DPkg::Lock::Timeout=600 install -y ca-certificates git

WPP_DIR="$(mktemp -d /root/wpp-install.XXXXXX)"
git -c http.version=HTTP/1.1 clone --depth 1 --branch v2.3.6 \
  https://github.com/POLESNIESOVETI12/web-panel-proxy.git "$WPP_DIR"

cd "$WPP_DIR"
chmod +x ./*.sh
bash ./install-final.sh
