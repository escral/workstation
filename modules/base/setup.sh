#!/usr/bin/env bash
set -euo pipefail
source "$WS_ROOT/lib/common.sh"

mkdir -p "$HOME/.local/bin"
ln -sfn "$WS_ROOT/bin/ws" "$HOME/.local/bin/ws"

sudo sed -i -e 's/^#Color$/Color/' -e 's/^#ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
