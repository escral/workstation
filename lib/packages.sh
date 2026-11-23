# shellcheck shell=bash

ensure_paru() {
  have paru && return 0
  log "installing paru (AUR helper)"
  local tmp
  tmp=$(mktemp -d)
  git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
  (cd "$tmp/paru-bin" && makepkg -si --noconfirm)
  rm -rf "$tmp"
}

# Install pacman + AUR packages for the given modules.
install_packages() {
  local m pac=() aur=()
  for m in "$@"; do
    mapfile -t -O "${#pac[@]}" pac < <(read_list "$WS_ROOT/modules/$m/packages")
    mapfile -t -O "${#aur[@]}" aur < <(read_list "$WS_ROOT/modules/$m/aur")
  done
  if ((${#pac[@]})); then
    log "pacman: ${#pac[@]} packages"
    sudo pacman -S --needed --noconfirm "${pac[@]}"
  fi
  if ((${#aur[@]})); then
    ensure_paru
    log "aur: ${#aur[@]} packages"
    paru -S --needed --noconfirm "${aur[@]}"
  fi
}

# Every package any module declares (enabled or not).
all_declared_packages() {
  local f
  for f in "$WS_ROOT"/modules/*/packages "$WS_ROOT"/modules/*/aur; do
    read_list "$f"
  done | sort -u
}
