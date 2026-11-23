#!/usr/bin/env bash
set -euo pipefail
dir="$HOME/.local/share/fzf-marks"
[[ -d $dir ]] || git clone --depth 1 https://github.com/urbainvaes/fzf-marks "$dir"
