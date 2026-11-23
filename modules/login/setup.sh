#!/usr/bin/env bash
# greetd + tuigreet. Default: Hyprland under uwsm; other sessions selectable (F3).
set -euo pipefail
sudo tee /etc/greetd/config.toml >/dev/null <<'CONF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-session --asterisks --cmd 'uwsm start hyprland.desktop'"
user = "greeter"
CONF
sudo systemctl enable greetd.service
