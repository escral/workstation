#!/usr/bin/env bash
# Docker writes iptables rules directly and bypasses ufw: bind published
# container ports to 127.0.0.1.
set -euo pipefail
sudo ufw default deny incoming
sudo ufw default allow outgoing
for rule in ${FIREWALL_ALLOW:-}; do
  sudo ufw allow "$rule"
done
sudo ufw --force enable
sudo systemctl enable --now ufw.service
