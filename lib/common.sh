# shellcheck shell=bash
# Shared helpers. Sourced by bin/ws and module hooks.

WS_ROOT="${WS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
WS_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/workstation"
WS_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/workstation"
export WS_ROOT WS_CONFIG WS_STATE

if [[ -t 1 ]]; then
  _c_blue=$'\e[34m' _c_yellow=$'\e[33m' _c_red=$'\e[31m' _c_dim=$'\e[2m' _c_off=$'\e[0m'
else
  _c_blue='' _c_yellow='' _c_red='' _c_dim='' _c_off=''
fi

log()  { printf '%s==>%s %s\n' "$_c_blue" "$_c_off" "$*"; }
info() { printf '%s    %s%s\n' "$_c_dim" "$*" "$_c_off"; }
warn() { printf '%swarn:%s %s\n' "$_c_yellow" "$_c_off" "$*" >&2; }
die()  { printf '%serror:%s %s\n' "$_c_red" "$_c_off" "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# Print non-empty, non-comment lines of a list file (packages, aur, ...).
read_list() {
  [[ -f $1 ]] || return 0
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^[[:space:]]*$/d' "$1"
}

# ---- profiles -------------------------------------------------------------

current_profile() {
  [[ -f $WS_CONFIG/profile ]] && cat "$WS_CONFIG/profile"
}

# Load a profile and its `extends` chain (parents first).
# Sets: modules (array, deduped), WS_PROFILE_CHAIN, and exports every flag
# the profile files define (GPU, AI_TIER, ...).
load_profile() {
  modules=()
  WS_PROFILE_CHAIN=()
  set -a
  _load_profile_rec "$1"
  set +a
  local -A seen=()
  local m out=()
  for m in "${modules[@]}"; do
    [[ -n ${seen[$m]:-} ]] && continue
    seen[$m]=1
    [[ -d $WS_ROOT/modules/$m ]] || die "profile references unknown module: $m"
    out+=("$m")
  done
  modules=("${out[@]}")
  export WS_PROFILE="$1"
}

_load_profile_rec() {
  local name=$1 file="$WS_ROOT/profiles/$1/profile.sh" parent
  [[ -f $file ]] || die "unknown profile: $name (no $file)"
  # shellcheck disable=SC1090
  parent=$(extends=''; source "$file" >/dev/null; printf '%s' "$extends")
  [[ -n $parent ]] && _load_profile_rec "$parent"
  extends=''
  # shellcheck disable=SC1090
  source "$file"
  WS_PROFILE_CHAIN+=("$name")
}

list_profiles() {
  local d
  for d in "$WS_ROOT"/profiles/*/; do
    d=${d%/}; d=${d##*/}
    [[ $d == base ]] || printf '%s\n' "$d"
  done
}
