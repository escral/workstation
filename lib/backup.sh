# shellcheck shell=bash

# App state goes to a ws-backup folder on a removable drive: a restic
# repository, encrypted with a password asked on every run and stored nowhere.

_ask() {
  local reply
  read -rp "$1 [Y/n] " reply
  [[ -z $reply || $reply == [yY]* ]]
}

_state_modules() {
  local m
  (($#)) || set -- "${modules[@]}"
  for m in "$@"; do
    [[ -d $WS_ROOT/modules/$m ]] || die "unknown module: $m"
    if [[ -f $WS_ROOT/modules/$m/state ]]; then printf '%s\n' "$m"; fi
  done
}

_state_paths() {
  read_list "$WS_ROOT/modules/$1/state" | sed "s|^|$HOME/|"
}

_users_of() {
  local p
  for p in "$@"; do
    [[ -e $p ]] || continue
    # find fails on other users' processes, so its output is the answer.
    find /proc/[0-9]*/fd -lname "$p/*" -printf '%h\n' 2>/dev/null || true
  done | cut -d/ -f3 | sort -u
}

# Copying an open profile catches SQLite files mid-write, and a restore under
# a running app gets overwritten when it exits.
_close_apps() {
  local pids names i
  mapfile -t pids < <(_users_of "$@")
  ((${#pids[@]})) || return 0
  names=$(ps -o comm= -p "${pids[@]}" | sort -u | paste -sd' ')
  _ask "running: $names. Close them?" || die "close them first"
  kill -TERM "${pids[@]}" 2>/dev/null || true
  for ((i = 0; i < 40; i++)); do
    [[ -z $(_users_of "$@") ]] && return 0
    sleep 0.5
  done
  die "still running: $names"
}

# Sets DRIVE_MNT, and DRIVE_DEV for a drive (empty for a folder given by hand).
_pick_drive() {
  local -a rows
  DRIVE_DEV='' DRIVE_MNT=''
  if [[ -n ${1:-} ]]; then
    [[ -d $1 ]] || die "no such folder: $1"
    DRIVE_MNT=$1
    return
  fi
  # Only whole disks carry the transport; their partitions hold the filesystems.
  mapfile -t rows < <(lsblk -J -o PATH,LABEL,SIZE,FSTYPE,TYPE,TRAN,RM,HOTPLUG,MOUNTPOINT | jq -r '
    .blockdevices[] | select(.type == "disk" and (.tran == "usb" or .rm or .hotplug))
    | (., .children[]?) | select(.fstype != null and .fstype != "swap")
    | [.path, (.label // "no label"), .size, (.mountpoint // "")] | @tsv')
  ((${#rows[@]})) || die "no removable drive found: plug one in, or give a folder"
  if ((${#rows[@]} > 1)); then
    local choice
    PS3="drive: "
    select choice in "${rows[@]//$'\t'/  }"; do [[ -n $choice ]] && break; done </dev/tty
    rows=("${rows[REPLY - 1]}")
  fi
  IFS=$'\t' read -r DRIVE_DEV _ _ DRIVE_MNT <<<"${rows[0]}"
  if [[ -z $DRIVE_MNT ]]; then
    udisksctl mount --block-device "$DRIVE_DEV" >/dev/null || die "could not mount $DRIVE_DEV"
    DRIVE_MNT=$(lsblk -no MOUNTPOINT "$DRIVE_DEV")
  fi
  log "drive: $DRIVE_MNT"
}

_eject() {
  [[ -n $DRIVE_DEV ]] || return 0
  sync
  _ask "eject $DRIVE_DEV?" || return 0
  udisksctl unmount --block-device "$DRIVE_DEV" >/dev/null
  udisksctl power-off --block-device "$DRIVE_DEV" 2>/dev/null || true
  log "the drive can be pulled out"
}

_ask_password() {
  local again
  read -rsp "backup password: " RESTIC_PASSWORD </dev/tty; echo
  if [[ ${1:-} == new ]]; then
    read -rsp "again: " again </dev/tty; echo
    [[ $again == "$RESTIC_PASSWORD" ]] || die "passwords differ"
  fi
  export RESTIC_PASSWORD
}

# Arguments: module names, and optionally a folder (anything with a /) to use
# instead of looking for a removable drive.
_parse_args() {
  local a
  where='' names=()
  for a in "$@"; do
    if [[ $a == */* ]]; then where=$a; else names+=("$a"); fi
  done
}

# Each module is its own snapshot, tagged with its name, so a machine restores
# only the apps its profile has, whichever machine saved them last.
cmd_backup() {
  load_profile "$(resolve_profile)"
  have restic || die "restic is missing: the backup module installs it"
  local where m p ms
  local -a names all=()
  _parse_args "$@"
  ms=$(_state_modules "${names[@]}")
  [[ -n $ms ]] || die "no active module has a state file"
  for m in $ms; do
    while IFS= read -r p; do all+=("$p"); done < <(_state_paths "$m")
  done
  _close_apps "${all[@]}"

  _pick_drive "$where"
  export RESTIC_REPOSITORY=$DRIVE_MNT/ws-backup
  if [[ -f $RESTIC_REPOSITORY/config ]]; then
    _ask_password
    restic cat config >/dev/null 2>&1 || die "wrong password"
  else
    log "new backup in $RESTIC_REPOSITORY"
    _ask_password new
    restic init --quiet >/dev/null
  fi

  local -a paths
  for m in $ms; do
    paths=()
    while IFS= read -r p; do
      [[ -e $p ]] && paths+=("$p")
    done < <(_state_paths "$m")
    if ((!${#paths[@]})); then
      info "$m: nothing to save yet"
      continue
    fi
    log "backup: $m"
    restic backup --quiet --skip-if-unchanged --tag "$m" \
      --exclude-file <(read_list "$WS_ROOT/modules/$m/state-exclude") "${paths[@]}"
  done
  _eject
}

# Existing state is moved aside, not merged with the snapshot: leftovers from
# another session can confuse the app.
cmd_restore() {
  load_profile "$(resolve_profile)"
  have restic || die "restic is missing: the backup module installs it"
  local where m p ms stamp have_snap='' keyring=0
  local -a names paths all=()
  _parse_args "$@"
  ms=$(_state_modules "${names[@]}")
  [[ -n $ms ]] || die "no active module has a state file"

  _pick_drive "$where"
  export RESTIC_REPOSITORY=$DRIVE_MNT/ws-backup
  [[ -f $RESTIC_REPOSITORY/config ]] || die "no backup in $DRIVE_MNT"
  _ask_password
  restic cat config >/dev/null 2>&1 || die "wrong password"

  for m in $ms; do
    if restic snapshots --quiet --tag "$m" --latest 1 --json | jq -e 'length > 0' >/dev/null; then
      have_snap+="$m "
      while IFS= read -r p; do all+=("$p"); done < <(_state_paths "$m")
    else
      info "$m: not in the backup"
    fi
  done
  [[ -n $have_snap ]] || die "nothing to restore"
  _close_apps "${all[@]}"

  stamp=$(date +%Y%m%d-%H%M%S)
  for m in $have_snap; do
    mapfile -t paths < <(_state_paths "$m")
    for p in "${paths[@]}"; do
      [[ -e $p ]] || continue
      mv "$p" "$p.before-restore-$stamp"
      info "kept ${p#"$HOME"/}.before-restore-$stamp"
    done
    log "restore: $m"
    restic restore --quiet latest --tag "$m" --target / >/dev/null
    [[ $m == keyring ]] && keyring=1
  done
  _eject
  # gnome-keyring keeps the keyring it opened at sign-in in memory.
  ((keyring)) && log "sign out and back in: the restored keyring opens at sign-in"
  return 0
}
