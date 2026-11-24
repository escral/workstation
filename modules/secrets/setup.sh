#!/usr/bin/env bash
set -euo pipefail
source "$WS_ROOT/lib/common.sh"
[[ -f $HOME/.config/git/identity ]] || info "next: ws secrets (SSH keys, ssh hosts, git identity)"
