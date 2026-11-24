#!/usr/bin/env bash
set -euo pipefail
# The socket, not the service: the daemon starts on first use, not at boot.
sudo systemctl enable --now docker.socket
# Takes effect at the next login.
id -nG "$USER" | grep -qw docker || sudo usermod -aG docker "$USER"

# Docker's own firewall rules bypass ufw, so a bare -p 8080:80 would open the
# port to the whole network. Published ports bind to localhost instead; open
# one on purpose with -p 0.0.0.0:8080:80.
daemon='{ "ip": "127.0.0.1" }'
if ! cmp -s /etc/docker/daemon.json <(printf '%s\n' "$daemon"); then
  printf '%s\n' "$daemon" | sudo install -Dm644 /dev/stdin /etc/docker/daemon.json
  sudo systemctl try-restart docker.service
fi
