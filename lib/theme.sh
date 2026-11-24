# shellcheck shell=bash
THEMED_LIST="$WS_STATE/themed"
DEFAULT_THEME=tokyo-night

current_theme() {
  if [[ -f $WS_CONFIG/theme ]]; then cat "$WS_CONFIG/theme"; else echo "$DEFAULT_THEME"; fi
}

list_themes() {
  local f
  for f in "$WS_ROOT"/themes/*; do printf '%s\n' "${f##*/}"; done
}

# Fills the global map `tokens` (name -> hex without "#"). A value may be the
# name of another token, which reads as a role: `accent blue`.
load_theme() {
  local file="$WS_ROOT/themes/$1" name value
  [[ -f $file ]] || die "unknown theme: $1 (available: $(list_themes | paste -sd' '))"
  declare -gA tokens=()
  while read -r name value _; do
    [[ -z $name || $name == \#* ]] && continue
    tokens[$name]=${value#\#}
  done <"$file"
  for name in "${!tokens[@]}"; do
    value=${tokens[$name]}
    [[ -n ${tokens[$value]:-} ]] && value=${tokens[$value]}
    [[ $value =~ ^[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$ ]] \
      || die "theme $1: '$name' is neither a colour nor another token's name"
    tokens[$name]=$value
  done
}

render_template() {
  local text name
  text=$(<"$1")
  while [[ $text =~ \{\{([a-z0-9_]+)\}\} ]]; do
    name=${BASH_REMATCH[1]}
    if [[ -z ${tokens[$name]:-} ]]; then
      warn "${1#"$WS_ROOT"/}: theme $THEME has no '$name'"
      return 1
    fi
    text=${text//"{{$name}}"/${tokens[$name]}}
  done
  printf '%s\n' "$text"
}

# Each module's theme/ mirrors ~ like home/, but its files are templates with
# {{token}} in place of colours, written out as real files. Unchanged output
# isn't rewritten: Quickshell reloads on every write.
render_theme() {
  local dir src rel out tmp backup_root
  local -A old=() new=()
  THEME=$(current_theme)
  load_theme "$THEME"
  if [[ -f $THEMED_LIST ]]; then
    while IFS= read -r rel; do [[ -n $rel ]] && old[$rel]=1; done <"$THEMED_LIST"
  fi
  backup_root="$WS_STATE/backup/$(date +%Y%m%d-%H%M%S)"
  for dir in "$@"; do
    [[ -d $dir/theme ]] || continue
    while IFS= read -r -d '' src; do
      rel=${src#"$dir/theme/"}
      out=$HOME/$rel
      new[$rel]=1
      mkdir -p "$(dirname "$out")"
      tmp=$(mktemp "$out.XXXXXX")
      render_template "$src" >"$tmp" || { rm "$tmp"; die "theme not applied"; }
      if [[ -f $out && ! -L $out ]] && cmp -s "$tmp" "$out"; then
        rm "$tmp"
        continue
      fi
      # Same rule as stow: a file nobody here wrote is kept aside, not lost.
      if [[ -f $out && ! -L $out && -z ${old[$rel]:-} ]]; then
        mkdir -p "$backup_root/$(dirname "$rel")"
        cp -p "$out" "$backup_root/$rel"
        warn "saved existing ~/$rel to $backup_root/$rel"
      fi
      chmod 644 "$tmp"
      mv "$tmp" "$out"
      info "themed $rel"
    done < <(find "$dir/theme" -type f -print0)
  done
  for rel in "${!old[@]}"; do
    [[ -n ${new[$rel]:-} ]] && continue
    rm -f "$HOME/$rel"
    info "removed ~/$rel"
  done
  mkdir -p "$WS_STATE"
  printf '%s\n' "${!new[@]}" | sort >"$THEMED_LIST"
}

# Apps that read their colours only at start pick a new theme up when opened
# again; these reload in place.
reload_theme() {
  if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && have hyprctl; then
    hyprctl reload >/dev/null
  fi
  pkill -USR2 -x ghostty || true
}
