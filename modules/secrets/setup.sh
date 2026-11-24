#!/usr/bin/env bash
set -euo pipefail
source "$WS_ROOT/lib/common.sh"
# The vault lives on Bitwarden's EU server; rbw defaults to the US one and
# reports a wrong password there.
rbw config set base_url https://vault.bitwarden.eu
[[ -f $HOME/.config/git/identity ]] || info "next: ws secrets (SSH keys, ssh hosts, git identity)"
