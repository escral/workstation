#!/usr/bin/env bash
set -euo pipefail
# The native build: no Node needed, and it updates itself.
[[ -x $HOME/.local/bin/claude ]] || curl -fsSL https://claude.ai/install.sh | bash
