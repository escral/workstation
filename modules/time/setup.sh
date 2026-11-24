#!/usr/bin/env bash
set -euo pipefail
source "$WS_ROOT/lib/common.sh"

[[ -n ${TIMEZONE:-} ]] || die "profile sets no TIMEZONE"
[[ -f /usr/share/zoneinfo/$TIMEZONE ]] || die "unknown TIMEZONE: $TIMEZONE"
[[ $(timedatectl show -p Timezone --value) == "$TIMEZONE" ]] || sudo timedatectl set-timezone "$TIMEZONE"
# Starts systemd-timesyncd, which ships with systemd: no package to add.
sudo timedatectl set-ntp true
