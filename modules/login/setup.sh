#!/usr/bin/env bash
set -euo pipefail

# The login screen is Quickshell's (the quickshell module installs it), shown
# full screen by cage. Keys match the session's: Caps Lock is Escape there.
# Qt would otherwise draw its own title bar around the one window.
env="WS_USER=$USER XKB_DEFAULT_LAYOUT=us XKB_DEFAULT_OPTIONS=caps:escape QT_WAYLAND_DISABLE_WINDOWDECORATION=1"
# virtio-gpu shows the hardware cursor upside down.
[[ ${GPU:-} == virtio ]] && env+=" WLR_NO_HARDWARE_CURSORS=1"
sudo tee /etc/greetd/config.toml >/dev/null <<CONF
[terminal]
vt = 1

[default_session]
command = "env $env cage -s -m last -- quickshell -p /etc/greetd/quickshell/greeter.qml"
user = "greeter"
CONF
sudo systemctl enable greetd.service

# Arch locks the account for 10 minutes after 3 wrong passwords, which a few
# typos on the lock screen hit easily.
sudo sed -i -E 's/^#? *deny = .*/deny = 10/' /etc/security/faillock.conf
