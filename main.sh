# Скачиваем последний релиз runsc
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    URL="https://storage.googleapis.com/gvisor/releases/release/latest/x86_64/runsc"
elif [ "$ARCH" = "aarch64" ]; then
    URL="https://storage.googleapis.com/gvisor/releases/release/latest/aarch64/runsc"
else
    echo "Неподдерживаемая архитектура: $ARCH"
    exit 1
fi

sudo curl -fsSL "$URL" -o /usr/local/bin/runsc
sudo curl -fsSL "${URL}.sha512" -o /tmp/runsc.sha512
sudo chmod +x /usr/local/bin/runsc

# Проверка
runsc --version

ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    SHIM_URL="https://storage.googleapis.com/gvisor/releases/release/latest/x86_64/containerd-shim-runsc-v1"
elif [ "$ARCH" = "aarch64" ]; then
    SHIM_URL="https://storage.googleapis.com/gvisor/releases/release/latest/aarch64/containerd-shim-runsc-v1"
fi

sudo curl -fsSL "$SHIM_URL" -o /usr/local/bin/containerd-shim-runsc-v1
sudo chmod +x /usr/local/bin/containerd-shim-runsc-v1
sudo tee /etc/containers/registries.conf.d/runsc.conf <<'EOF'
[engine.runtimes]
runsc = [
  "/usr/local/bin/runsc",
  "/usr/local/bin/containerd-shim-runsc-v1"
]
EOF
sudo podman run --rm --runtime=runsc --platform=systrap --ignore-cgroups docker.io/library/alpine echo "gVisor works!"
