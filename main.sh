cat > /root/setup-reality.sh << 'EOF'
#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Установка VLESS Reality автоматически${NC}"
echo -e "${GREEN}========================================${NC}"

# Получаем IP сервера
SERVER_IP=$(curl -s ifconfig.me || curl -s ipv4.icanhazip.com || curl -s ipapi.co/ip)
if [ -z "$SERVER_IP" ]; then
    echo -e "${RED}Не удалось определить IP сервера${NC}"
    read -p "Введите IP вручную: " SERVER_IP
fi
echo -e "${GREEN}IP сервера: $SERVER_IP${NC}"

# Генерация ключей
echo -e "${YELLOW}Генерация ключей Reality...${NC}"
XRAY_OUTPUT=$(/usr/local/bin/xray x25519)
PRIVATE_KEY=$(echo "$XRAY_OUTPUT" | grep "Private key" | awk '{print $3}')
PUBLIC_KEY=$(echo "$XRAY_OUTPUT" | grep "Public key" | awk '{print $3}')

# Генерация UUID
echo -e "${YELLOW}Генерация UUID...${NC}"
UUID=$(/usr/local/bin/xray uuid)

# Генерация Short ID
echo -e "${YELLOW}Генерация Short ID...${NC}"
SHORT_ID=$(openssl rand -hex 8)

# Вывод сгенерированных данных
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Сгенерированные данные:${NC}"
echo -e "Private Key: ${YELLOW}$PRIVATE_KEY${NC}"
echo -e "Public Key:  ${YELLOW}$PUBLIC_KEY${NC}"
echo -e "UUID:        ${YELLOW}$UUID${NC}"
echo -e "Short ID:    ${YELLOW}$SHORT_ID${NC}"
echo -e "${GREEN}========================================${NC}"

# Запрос SNI (сайта для маскировки)
read -p "Введите SNI (по умолчанию web.yota.ru): " SNI
SNI=${SNI:-web.yota.ru}
echo -e "${GREEN}Используем SNI: $SNI${NC}"

# Запрос порта
read -p "Введите порт (по умолчанию 443): " PORT
PORT=${PORT:-443}
echo -e "${GREEN}Используем порт: $PORT${NC}"

# Создание конфига
echo -e "${YELLOW}Создание конфигурационного файла...${NC}"

cat > /usr/local/etc/xray/config.json << JSON
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-vision",
            "email": "user1@example.com"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "$SNI:443",
          "serverNames": [
            "$SNI"
          ],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [
            "$SHORT_ID"
          ],
          "settings": {
            "publicKey": "$PUBLIC_KEY",
            "fingerprint": "chrome"
          }
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "block"
    }
  ]
}
JSON

echo -e "${GREEN}Конфиг создан: /usr/local/etc/xray/config.json${NC}"

# Открытие порта в файрволе
echo -e "${YELLOW}Настройка файрвола...${NC}"
if command -v ufw &> /dev/null; then
    ufw allow $PORT/tcp
    echo -e "${GREEN}Порт $PORT открыт в ufw${NC}"
elif command -v iptables &> /dev/null; then
    iptables -I INPUT -p tcp --dport $PORT -j ACCEPT
    echo -e "${GREEN}Порт $PORT открыт в iptables${NC}"
fi

# Перезапуск Xray
echo -e "${YELLOW}Перезапуск Xray...${NC}"
systemctl restart xray

# Проверка статуса
sleep 2
if systemctl is-active --quiet xray; then
    echo -e "${GREEN}✅ Xray успешно запущен!${NC}"
else
    echo -e "${RED}❌ Ошибка запуска Xray. Проверьте логи:${NC}"
    journalctl -u xray -n 20
    exit 1
fi

# Формирование ссылки
VLESS_LINK="vless://$UUID@$SERVER_IP:$PORT?type=tcp&security=reality&pbk=$PUBLIC_KEY&fp=chrome&sni=$SNI&sid=$SHORT_ID&flow=xtls-rprx-vision#MyReality"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ НАСТРОЙКА ЗАВЕРШЕНА!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}Ссылка для подключения:${NC}"
echo -e "${GREEN}$VLESS_LINK${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}Данные для клиента:${NC}"
echo -e "IP:      $SERVER_IP"
echo -e "Port:    $PORT"
echo -e "UUID:    $UUID"
echo -e "Public Key: $PUBLIC_KEY"
echo -e "Short ID:   $SHORT_ID"
echo -e "SNI:        $SNI"
echo -e "Flow:       xtls-rprx-vision"
echo -e "Fingerprint: chrome"
echo -e "${GREEN}========================================${NC}"

# Сохранение в файл
cat > /root/reality-info.txt << EOF
========================================
VLESS REALITY КОНФИГУРАЦИЯ
========================================
IP сервера:   $SERVER_IP
Порт:         $PORT
UUID:         $UUID
Public Key:   $PUBLIC_KEY
Private Key:  $PRIVATE_KEY
Short ID:     $SHORT_ID
SNI:          $SNI
Flow:         xtls-rprx-vision
Fingerprint:  chrome
========================================
Ссылка для клиента:
$VLESS_LINK
========================================
EOF

echo -e "${GREEN}Информация сохранена в: /root/reality-info.txt${NC}"
echo -e "${GREEN}========================================${NC}"
EOF

# Делаем скрипт исполняемым
chmod +x /root/setup-reality.sh

# Запускаем
bash /root/setup-reality.sh
