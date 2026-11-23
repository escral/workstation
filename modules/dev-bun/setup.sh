#!/usr/bin/env bash
# Bun via its official installer (installs to ~/.bun).
set -euo pipefail
[[ -x $HOME/.bun/bin/bun ]] && exit 0
curl -fsSL https://bun.sh/install | bash
