# shellcheck shell=bash

# Writes one vault file into ~, unless a local copy differs (kept without
# --force, so an edit made here isn't lost to an older copy in the vault).
put_secret() {
  local force=$1 name=$2 content=$3 path=$HOME/$2
  [[ -n $content ]] || { warn "skipped '$name': empty"; return; }
  if [[ -L $path ]]; then
    warn "skipped ~/$name: a stowed file from the repo"
    return
  fi
  if [[ -f $path ]]; then
    cmp -s "$path" <(printf '%s\n' "$content") && return
    if ((!force)); then
      warn "kept ~/$name: differs from the vault (--force to replace)"
      return
    fi
  fi
  (umask 077; mkdir -p "$(dirname "$path")"; printf '%s\n' "$content" >"$path")
  chmod 600 "$path"
  log "wrote ~/$name"
}

# Every item in the Bitwarden folder "workstation" is named by its path under
# ~. An SSH key item gives the key and its .pub (.ssh/id_rsa); a secure note
# gives its text (.ssh/config.local, .config/git/identity).
cmd_secrets() {
  local force=0 name folder raw
  [[ ${1:-} == --force ]] && force=1
  have rbw || die "rbw is missing: the secrets module installs it"
  if [[ -z $(rbw config show | jq -r '.email // empty') ]]; then
    read -rp "Bitwarden email: " name
    rbw config set email "$name"
  fi
  rbw unlock
  rbw sync
  while IFS=$'\t' read -r name folder; do
    [[ $folder == workstation ]] || continue
    if [[ $name == /* || $name == *..* ]]; then
      warn "skipped '$name': not a path under ~"
      continue
    fi
    raw=$(rbw get --folder workstation --raw "$name")
    # $(...) drops trailing newlines; put_secret adds one back, as keys need.
    if jq -e '.data.private_key' >/dev/null <<<"$raw"; then
      put_secret "$force" "$name" "$(jq -j '.data.private_key' <<<"$raw")"
      put_secret "$force" "$name.pub" "$(jq -j '.data.public_key // ""' <<<"$raw")"
    else
      put_secret "$force" "$name" "$(jq -j '.notes // ""' <<<"$raw")"
    fi
  done < <(rbw list --fields name,folder)
}
