systemctl restart xray 2>/dev/null || (pkill -f xray; /usr/local/bin/xray -config /usr/local/etc/xray/config.json &)
