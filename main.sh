apt-get clean && apt-get autoremove --purge -y
journalctl --vacuum-size=10M
snap set system refresh.retain=2 && snap list --all | awk '/disabled/{print $1, $3}' | while read snapname rev; do snap remove "$snapname" --revision="$rev"; done
