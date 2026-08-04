docker stop tg-proxy && docker rm tg-proxy

#!/usr/bin/env bash
#
# setup-mtproxy.sh
# Автоматизация установки Telegram MTProxy (kr-ilya/mtproxy-docker) с FakeTLS.
#
# Использование:
#   sudo ./setup-mtproxy.sh
#
# Настройки можно передать через переменные окружения перед запуском, например:
#   PORT=8443 FAKE_TLS_DOMAIN=www.microsoft.com TAG=xxx sudo -E ./setup-mtproxy.sh
#
# Либо просто отредактировать блок "НАСТРОЙКИ" ниже.

set -euo pipefail

# ============================================================
# НАСТРОЙКИ (можно переопределить через env-переменные)
# ============================================================
REPO_URL="https://github.com/kr-ilya/mtproxy-docker.git"
INSTALL_DIR="${INSTALL_DIR:-/opt/mtproxy-docker}"

PORT="8443"
SECRET="${SECRET:-}"                     # пусто = сгенерировать автоматически
TAG="${TAG:-}"                           # тег из @MTProxybot, можно оставить пустым
FAKE_TLS="${FAKE_TLS:-1}"
FAKE_TLS_DOMAIN="${FAKE_TLS_DOMAIN:-cloudflare.com}"
WORKERS="${WORKERS:-4}"
STATS_PORT="${STATS_PORT:-8888}"
CONFIG_UPDATE_INTERVAL="${CONFIG_UPDATE_INTERVAL:-604800}"

APPLY_PID_MAX_FIX="${APPLY_PID_MAX_FIX:-1}"   # 1 = применить обходной путь для PID>65535

# ============================================================

log()  { echo -e "\033[1;32m[+]\033[0m $*"; }
warn() { echo -e "\033[1;33m[!]\033[0m $*"; }
err()  { echo -e "\033[1;31m[x]\033[0m $*" >&2; }

if [[ $EUID -ne 0 ]]; then
  err "Запустите скрипт с sudo/от root: sudo $0"
  exit 1
fi

# ------------------------------------------------------------
# 1. Установка Docker и Docker Compose plugin, если их нет
# ------------------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
  log "Docker не найден, устанавливаю..."
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
else
  log "Docker уже установлен: $(docker --version)"
fi

if ! docker compose version >/dev/null 2>&1; then
  err "Docker Compose plugin не найден. Установите docker-compose-plugin вручную и перезапустите скрипт."
  exit 1
fi

# ------------------------------------------------------------
# 2. Генерация secret, если не задан
# ------------------------------------------------------------
if [[ -z "$SECRET" ]]; then
  SECRET=$(openssl rand -hex 16)
  log "SECRET не задан, сгенерирован новый: $SECRET"
fi

if [[ ! "$SECRET" =~ ^[0-9a-fA-F]{32}$ ]]; then
  err "SECRET должен быть 32 hex-символа (16 байт). Получено: '$SECRET'"
  exit 1
fi

# ------------------------------------------------------------
# 3. Обходной путь для бага с PID > 65535 (опционально)
# ------------------------------------------------------------
if [[ "$APPLY_PID_MAX_FIX" == "1" ]]; then
  log "Применяю kernel.pid_max = 65535 (обход бага official MTProxy с большими PID)..."
  echo "kernel.pid_max = 65535" > /etc/sysctl.d/99-mtproxy.conf
  sysctl --system > /dev/null
fi

# ------------------------------------------------------------
# 4. Клонирование / обновление репозитория
# ------------------------------------------------------------
if [[ -d "$INSTALL_DIR/.git" ]]; then
  log "Репозиторий уже склонирован в $INSTALL_DIR, обновляю..."
  git -C "$INSTALL_DIR" pull
else
  log "Клонирую $REPO_URL в $INSTALL_DIR..."
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# ------------------------------------------------------------
# 5. Генерация .env
# ------------------------------------------------------------
log "Пишу конфигурацию в .env..."
cat > .env <<EOF
PORT=${PORT}
SECRET=${SECRET}
TAG=${TAG}
FAKE_TLS=${FAKE_TLS}
FAKE_TLS_DOMAIN=${FAKE_TLS_DOMAIN}
WORKERS=${WORKERS}
STATS_PORT=${STATS_PORT}
CONFIG_UPDATE_INTERVAL=${CONFIG_UPDATE_INTERVAL}
EOF

# ------------------------------------------------------------
# 6. Запуск
# ------------------------------------------------------------
log "Запускаю docker compose..."
docker compose up -d

log "Готово! Жду 5 секунд и показываю логи с ссылкой подключения..."
sleep 5
docker compose logs --tail=50

EXTERNAL_IP=$(curl -s -4 ifconfig.me || echo "YOUR_SERVER_IP")

echo ""
echo "======================================================"
echo " MTProxy запущен"
echo " Server:  ${EXTERNAL_IP}"
echo " Port:    ${PORT}"
echo " Secret:  ${SECRET}   (без префикса)"
echo ""
echo " Ссылка для подключения (FakeTLS, домен: ${FAKE_TLS_DOMAIN}):"
echo " tg://proxy?server=${EXTERNAL_IP}&port=${PORT}&secret=ee${SECRET}$(echo -n "${FAKE_TLS_DOMAIN}" | xxd -p | tr -d '\n')"
echo ""
echo " Конфиг:  ${INSTALL_DIR}/.env"
echo " Логи:    cd ${INSTALL_DIR} && docker compose logs -f"
echo " Обновить: cd ${INSTALL_DIR} && docker compose pull mtproxy && docker compose up -d --force-recreate"
echo "======================================================"
