#!/usr/bin/env bash
set -euo pipefail
source "$WS_ROOT/lib/common.sh"
systemctl --user enable app-com.mitchellh.ghostty.service || warn "could not enable ghostty service (no user bus?)"
