#!/usr/bin/env bash
set -euo pipefail
source "$WS_ROOT/lib/common.sh"
xdg-user-dirs-update
systemctl --user enable hyprpolkitagent.service || warn "could not enable hyprpolkitagent (no user bus?)"
