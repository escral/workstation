#!/usr/bin/env bash
set -euo pipefail
[[ -x $HOME/.bun/bin/bun ]] && exit 0
curl -fsSL https://bun.sh/install | bash
