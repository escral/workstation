#!/usr/bin/env bash
set -euo pipefail

WS_REPO=${WS_REPO:-https://github.com/escral/workstation.git}
WS_ROOT=${WS_ROOT:-$HOME/workstation}
WS_BRANCH=${WS_BRANCH:-master}
WS_PROFILE=${WS_PROFILE:-}

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

[[ -f /etc/arch-release ]] || die "this targets Arch Linux"
[[ $EUID -ne 0 ]] || die "run as your normal user, not root (sudo is used where needed)"

echo "==> base tools"
sudo pacman -Syu --needed --noconfirm git base-devel stow

if [[ -d $WS_ROOT/.git ]]; then
  echo "==> $WS_ROOT exists, pulling"
  git -C "$WS_ROOT" pull --ff-only || true
else
  echo "==> cloning into $WS_ROOT"
  git clone --branch "$WS_BRANCH" "$WS_REPO" "$WS_ROOT"
fi

if [[ -z $WS_PROFILE ]]; then
  mapfile -t profiles < <(find "$WS_ROOT/profiles" -mindepth 1 -maxdepth 1 -type d ! -name base -printf '%f\n' | sort)
  echo "==> profiles: ${profiles[*]}"
  # stdin is this script when piped from curl; read from the terminal.
  read -rp "profile: " WS_PROFILE </dev/tty
fi

exec "$WS_ROOT/bin/ws" install --profile "$WS_PROFILE"
