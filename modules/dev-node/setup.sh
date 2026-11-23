#!/usr/bin/env bash
set -euo pipefail
eval "$(fnm env --shell bash)"
fnm list | grep -q lts-latest || fnm install --lts
