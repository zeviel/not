
systemctl disable x-ui
rm -rf /usr/local/x-ui /etc/systemd/system/x-ui.service
systemctl daemon-reload
