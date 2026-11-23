#!/usr/bin/env bash
# Deny incoming, allow outgoing. Note: Docker publishes ports by writing
# iptables rules directly and bypasses ufw — bind containers to 127.0.0.1.
set -euo pipefail
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw --force enable
sudo systemctl enable --now ufw.service
