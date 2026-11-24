#!/usr/bin/env bash
set -euo pipefail
source "$WS_ROOT/lib/common.sh"

# Plugins install on the first start and grammars build on the first open,
# so both happen here instead, before nvim is ever opened for real.
# nvim leaves its last progress line without a newline.
nvim --headless -c 'lua require("nvim-treesitter").install(require("parsers")):wait(600000)' -c 'qa' 2>&1 \
  | sed '$a\'
