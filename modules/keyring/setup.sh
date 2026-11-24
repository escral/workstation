#!/usr/bin/env bash
# Chrome, Slack and other Chromium apps keep the key to their cookies and
# passwords here. The login password unlocks it at sign-in through PAM, so a
# keyring restored on another machine opens only if that password matches.
set -euo pipefail

pam=/etc/pam.d/greetd
if [[ -f $pam ]] && ! grep -q pam_gnome_keyring "$pam"; then
  sudo sed -i \
    -e '/^auth .*include .*system-local-login/a auth       optional     pam_gnome_keyring.so' \
    -e '/^session .*include .*system-local-login/a session    optional     pam_gnome_keyring.so auto_start' \
    "$pam"
fi
