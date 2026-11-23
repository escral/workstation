#!/usr/bin/env bash
set -euo pipefail
sudo tee /etc/greetd/config.toml >/dev/null <<'CONF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-session --asterisks --cmd 'uwsm start hyprland.desktop' --theme 'border=blue;title=blue;text=gray;prompt=lightblue;time=gray;action=darkgray;button=blue;container=black;input=white'"
user = "greeter"
CONF
sudo systemctl enable greetd.service

# Arch locks the account for 10 minutes after 3 wrong passwords, which a few
# typos on the lock screen hit easily.
sudo sed -i -E 's/^#? *deny = .*/deny = 10/' /etc/security/faillock.conf
