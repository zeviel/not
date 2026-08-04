cat << 'EOF' > /etc/mtg-proxy/config.toml
secret = "eec741a811908c5b4238dee60fc14c784c7765622e796f74612e7275"
tag = "b62807b6682914bcbde6f432b20b89f4"
bind-to = "[::]:8443"
auto-update = true
allow-fallback-on-unknown-dc = true
EOF
