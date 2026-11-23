#!/usr/bin/env bash
set -euo pipefail

zsh_path=$(command -v zsh)
if [[ $(getent passwd "$USER" | cut -d: -f7) != "$zsh_path" ]]; then
  sudo chsh -s "$zsh_path" "$USER"
fi

# ~/.zshenv and ~/.zshrc are real files that load the repo config, not links:
# installers (rustup, pnpm, ...) append to them and must not edit the repo.
ensure_loader() {
  local file=$1 line=$2 tmp
  [[ -f $file && ! -L $file ]] && grep -qxF "$line" "$file" && return 0
  [[ -L $file ]] && rm "$file"
  tmp=$(mktemp)
  { echo "$line"; [[ -f $file ]] && cat "$file"; } >"$tmp"
  mv "$tmp" "$file"
  chmod 644 "$file"
}
ensure_loader "$HOME/.zshenv" '. "$HOME/.config/zsh/zshenv"'
ensure_loader "$HOME/.zshrc" 'source "$HOME/.config/zsh/zshrc"'
