# shellcheck shell=bash
stow_home() {
  local pkg_dir=$1 label=$2
  [[ -d $pkg_dir/home ]] || return 0
  _backup_conflicts "$pkg_dir/home"
  stow --no-folding --restow -d "$pkg_dir" -t "$HOME" home \
    || die "stow failed for $label"
  info "stowed $label"
}

unstow_home() {
  local pkg_dir=$1
  [[ -d $pkg_dir/home ]] || return 0
  stow --no-folding --delete -d "$pkg_dir" -t "$HOME" home
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
