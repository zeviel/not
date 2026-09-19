rm -rf ~/.cache/olcrtc
rm -rf /tmp/olcrtc-*
rm -rf /tmp/go-build*
sudo apt-get clean
sudo apt-get autoremove -y
sudo journalctl --vacuum-size=50M
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

cd olcrtc

podman run --rm \
  --runtime=crun \
  --ulimit nofile=65536:65536 \
  --network host \
  -v "$(pwd)":/app:Z \
  -w /app \
  docker.io/library/golang:1.26-alpine3.22 \
  sh -c "go mod download && go build -trimpath -ldflags='-s -w' -o olcrtc ./cmd/olcrtc"
