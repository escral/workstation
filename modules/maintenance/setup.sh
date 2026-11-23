#!/usr/bin/env bash
# No unattended upgrades on Arch: a rolling system should be upgraded while
# you watch. Instead: weekly cache cleanup now, update notifier later
# (Quickshell widget reading `checkupdates`), upgrades via `ws update`.
set -euo pipefail
sudo systemctl enable --now paccache.timer
