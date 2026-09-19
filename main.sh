#!/bin/bash
set -euo pipefail

# ============================================
# Установка последнего релиза gVisor (runsc)
# ============================================

# Проверяем архитектуру
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|aarch64)
        echo "Архитектура: $ARCH"
        ;;
    *)
        echo "Неподдерживаемая архитектура: $ARCH"
        exit 1
        ;;
esac

# Нужны права root
if [ "$(id -u)" -ne 0 ]; then
    echo "Запустите скрипт от root или через sudo"
    exit 1
fi

# Устанавливаем зависимости (curl + zstd)
if ! command -v curl >/dev/null 2>&1; then
    apt-get update -qq
    apt-get install -y -qq curl ca-certificates
fi
if ! command -v zstd >/dev/null 2>&1; then
    apt-get update -qq
    apt-get install -y -qq zstd
fi

# Скачиваем и устанавливаем последний релиз
URL="https://storage.googleapis.com/gvisor/releases/release/latest/${ARCH}"
TMPDIR=$(mktemp -d)
cd "$TMPDIR"

echo "Скачиваем gVisor..."
curl -fsSL "${URL}/gvisor.tar.zstd" -o gvisor.tar.zstd
curl -fsSL "${URL}/gvisor.tar.zstd.sha512" -o gvisor.tar.zstd.sha512

echo "Проверяем контрольную сумму..."
sha512sum -c gvisor.tar.zstd.sha512

echo "Устанавливаем в /usr/local/bin..."
tar --zstd -xf gvisor.tar.zstd -C /usr/local/bin
chmod +x /usr/local/bin/runsc /usr/local/bin/containerd-shim-runsc-v1

# Очистка
cd /
rm -rf "$TMPDIR"

# Проверка
echo "Установленная версия:"
runsc --version

# ============================================
# Настройка Podman (если установлен)
# ============================================

if command -v podman >/dev/null 2>&1; then
    echo "Настраиваем runtime runsc для Podman..."

    mkdir -p /etc/containers
    cat > /etc/containers/containers.conf << 'EOF'
[engine]
# Можно оставить crun по умолчанию
# runtime = "crun"

[engine.runtimes]
runsc = [
  "/usr/local/bin/runsc",
]
EOF

    echo "Тестовый запуск контейнера через gVisor..."
    # --runtime-flag=ignore-cgroups нужен в некоторых окружениях
    # (в т.ч. в ограниченных sandbox-средах)
    podman run --rm \
        --runtime=runsc \
        --runtime-flag=ignore-cgroups \
        docker.io/library/alpine \
        echo "gVisor works!"
else
    echo "Podman не установлен — пропускаем настройку runtime и тест."
    echo "После установки Podman добавьте runtime вручную:"
    echo '  [engine.runtimes]'
    echo '  runsc = ["/usr/local/bin/runsc"]'
fi

echo "Готово."
