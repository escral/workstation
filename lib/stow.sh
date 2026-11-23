# shellcheck shell=bash
STOWED_LIST="$WS_STATE/stowed"

stow_home() {
  local pkg_dir=$1
  [[ -d $pkg_dir/home ]] || return 0
  _backup_conflicts "$pkg_dir/home"
  stow --no-folding --restow -d "$pkg_dir" -t "$HOME" home \
    || die "stow failed for ${pkg_dir#"$WS_ROOT"/}"
  info "stowed ${pkg_dir#"$WS_ROOT"/}"
}

# A module that left the profile still has live links (its files exist), so
# only a record of what was stowed last time can find them.
unstow_removed() {
  [[ -f $STOWED_LIST ]] || return 0
  local old
  while IFS= read -r old; do
    [[ " $* " == *" $old "* || ! -d $old/home ]] && continue
    stow --no-folding --delete -d "$old" -t "$HOME" home
    info "unstowed ${old#"$WS_ROOT"/}"
  done <"$STOWED_LIST"
}

record_stowed() {
  mkdir -p "$WS_STATE"
  printf '%s\n' "$@" >"$STOWED_LIST"
}

# Files deleted from the repo leave dangling links behind; restow can't see them.
prune_dead_links() {
  local link
  while IFS= read -r -d '' link; do
    [[ $(readlink -m "$link") == "$WS_ROOT"/* ]] || continue
    rm "$link"
    info "removed dead link ${link#"$HOME"/}"
  done < <(find "$HOME" -maxdepth 1 -xtype l -print0
           find "$HOME/.config" "$HOME/.local" -xtype l -print0 2>/dev/null)
}

# Move real files out of the way so distro defaults (.bashrc etc) never
# block stow on a fresh machine.
_backup_conflicts() {
  local src=$1 rel target backup_root
  backup_root="$WS_STATE/backup/$(date +%Y%m%d-%H%M%S)"
  while IFS= read -r -d '' rel; do
    rel=${rel#"$src"/}
    target="$HOME/$rel"
    if [[ -e $target && ! -L $target ]]; then
      mkdir -p "$backup_root/$(dirname "$rel")"
      mv "$target" "$backup_root/$rel"
      warn "moved existing ~/$rel to $backup_root/$rel"
    fi
  done < <(find "$src" \( -type f -o -type l \) -print0)
}
