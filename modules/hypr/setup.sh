#!/usr/bin/env bash
set -euo pipefail
source "$WS_ROOT/lib/common.sh"
xdg-user-dirs-update
# Polkit agent as a user service, started with the uwsm session.
systemctl --user enable hyprpolkitagent.service || warn "could not enable hyprpolkitagent (no user bus?)"
