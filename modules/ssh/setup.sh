#!/usr/bin/env bash
set -euo pipefail
source "$WS_ROOT/lib/common.sh"
# Stow creates ~/.ssh with default permissions; ssh wants it private.
chmod 700 "$HOME/.ssh"
systemctl --user enable --now ssh-agent.socket || warn "could not enable ssh-agent (no user bus?)"
