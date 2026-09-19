git clone --depth 1 --recurse-submodules https://github.com/openlibrecommunity/olcrtc.git
cd olcrtc

podman run --rm \
  --runtime=crun \
  --ulimit nofile=65536:65536 \
  --network host \
  -v "$(pwd)":/app:Z \
  -w /app \
  docker.io/library/golang:1.26-alpine3.22 \
  sh -c "go mod download && go build -trimpath -ldflags='-s -w' -o olcrtc ./cmd/olcrtc"
