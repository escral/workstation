#!/usr/bin/env bash
# Docker writes iptables rules directly and bypasses ufw: bind published
# container ports to 127.0.0.1.
set -euo pipefail
sudo ufw default deny incoming >/dev/null
sudo ufw default allow outgoing >/dev/null
for rule in ${FIREWALL_ALLOW:-}; do
  sudo ufw allow "$rule" >/dev/null
done
sudo ufw --force enable >/dev/null
sudo systemctl enable --now ufw.service
