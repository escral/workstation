#!/usr/bin/env bash
# VM harness: test a full install without touching the real machine.
#
#   base.qcow2   clean minimal Arch (btrfs, sshd, sudo user), built unattended
#   fresh.qcow2  throwaway overlay on top of base; `ws vm fresh` resets it
#
# Host needs only QEMU + python3. KVM strongly recommended; without it QEMU
# falls back to software emulation (TCG): fine for headless install tests,
# far too slow for a usable Hyprland session.
set -euo pipefail

WS_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
source "$WS_ROOT/lib/common.sh"

VM_DIR=${WS_VM_DIR:-$WS_ROOT/.vm}
BASE=$VM_DIR/base.qcow2
FRESH=$VM_DIR/fresh.qcow2
ISO=$VM_DIR/archlinux-x86_64.iso
KEY=$VM_DIR/id_ed25519
MIRROR=${WS_VM_MIRROR:-https://geo.mirror.pkgbuild.com/iso/latest}
SSH_PORT=${WS_VM_SSH_PORT:-2222}
SEED_PORT=${WS_VM_SEED_PORT:-8471}
VM_USER=${WS_VM_USER:-$USER}
MEM=${WS_VM_MEM:-8G}
CPUS=${WS_VM_CPUS:-4}
DISK_SIZE=${WS_VM_DISK:-40G}
HEADLESS=${WS_VM_HEADLESS:-0}

usage() {
  cat <<USAGE
usage: ws vm <command>

  check    verify KVM / QEMU on this host
  base     build base.qcow2 unattended (downloads Arch ISO once)
  fresh    reset overlay to clean base, boot, run boot.sh from committed repo
  run      boot the current overlay as-is (keeps state)
  sync     copy working tree (incl. uncommitted) into running VM, run ws install
  ssh      shell into running VM

env: WS_VM_HEADLESS=1 (no window), WS_VM_MEM, WS_VM_CPUS, WS_VM_DISK,
     WS_VM_SSH_PORT, WS_VM_USER
USAGE
}

has_kvm() { [[ -r /dev/kvm && -w /dev/kvm ]]; }

ssh_as() {
  local user=$1; shift
  ssh -p "$SSH_PORT" -i "$KEY" -o IdentitiesOnly=yes \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o LogLevel=ERROR "$user@localhost" "$@"
}
ssh_vm() { ssh_as "$VM_USER" "$@"; }

wait_ssh() {
  local user=$1 qpid=$2 tries=${3:-400}
  log "waiting for ssh ($user@localhost:$SSH_PORT)"
  while ((tries--)); do
    kill -0 "$qpid" 2>/dev/null || die "QEMU exited before ssh came up"
    ssh_as "$user" -o ConnectTimeout=3 -o BatchMode=yes true 2>/dev/null && return 0
    sleep 3
  done
  die "VM did not come up on ssh"
}

ensure_key() {
  mkdir -p "$VM_DIR"
  [[ -f $KEY ]] || ssh-keygen -q -t ed25519 -N '' -C ws-vm -f "$KEY"
}

cmd_check() {
  local ok=1
  if has_kvm; then info "kvm: ok"
  elif [[ -e /dev/kvm ]]; then warn "no access to /dev/kvm — sudo usermod -aG kvm $USER, re-login"
  else warn "/dev/kvm missing — enable VT-x / SVM in BIOS (falls back to slow TCG)"; fi
  have qemu-system-x86_64 && info "qemu: ok" || { warn "qemu-system-x86_64 missing"; ok=0; }
  have qemu-img && info "qemu-img: ok" || { warn "qemu-img missing"; ok=0; }
  have python3 && info "python3: ok" || { warn "python3 missing (serves cloud-init seed)"; ok=0; }
  ((ok)) || die "host not ready"
}

# Boot a disk. Extra args are appended (e.g. -cdrom).
qemu_boot() {
  local disk=$1; shift
  local accel=(-accel kvm -cpu host) display=(-device virtio-vga-gl -display gtk,gl=on)
  if ! has_kvm; then
    warn "no KVM: using TCG software emulation (slow)"
    accel=(-accel tcg -cpu max)
  fi
  if ((HEADLESS)) || ! has_kvm; then
    display=(-device virtio-vga -display none)
  fi
  qemu-system-x86_64 \
    "${accel[@]}" -smp "$CPUS" -m "$MEM" \
    -drive file="$disk",if=virtio,format=qcow2 \
    -nic user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:"$SSH_PORT"-:22 \
    "${display[@]}" \
    -device qemu-xhci -device usb-tablet \
    -virtfs local,path="$WS_ROOT",mount_tag=ws,security_model=none,readonly=on \
    "$@"
}

fetch_iso() {
  [[ -f $ISO ]] && return 0
  log "downloading Arch ISO from $MIRROR"
  curl -fL --progress-bar -o "$ISO.part" "$MIRROR/archlinux-x86_64.iso"
  log "verifying checksum"
  local want got
  want=$(curl -fsSL "$MIRROR/sha256sums.txt" | awk '$2 ~ /archlinux-x86_64\.iso$/ {print $1}')
  got=$(sha256sum "$ISO.part" | cut -d' ' -f1)
  [[ -n $want && $want == "$got" ]] || { rm -f "$ISO.part"; die "ISO checksum mismatch"; }
  mv "$ISO.part" "$ISO"
}

# cloud-init NoCloud seed served over HTTP: the live ISO picks it up via
# SMBIOS serial and installs our key for root, so we can ssh in.
start_seed_server() {
  local seed=$VM_DIR/seed
  mkdir -p "$seed"
  printf 'instance-id: ws-vm-%s\nlocal-hostname: archiso\n' "$(date +%s)" >"$seed/meta-data"
  cat >"$seed/user-data" <<EOF
#cloud-config
users:
  - name: root
    ssh_authorized_keys:
      - $(cat "$KEY.pub")
EOF
  python3 -m http.server --bind 127.0.0.1 --directory "$seed" "$SEED_PORT" >/dev/null 2>&1 &
  SEED_PID=$!
}

cmd_base() {
  cmd_check
  [[ -f $BASE ]] && die "$BASE exists. Delete it to rebuild."
  ensure_key
  fetch_iso
  rm -f "$BASE.part"
  qemu-img create -q -f qcow2 "$BASE.part" "$DISK_SIZE"

  start_seed_server
  local qpid
  qemu_boot "$BASE.part" -cdrom "$ISO" -boot d \
    -smbios "type=1,serial=ds=nocloud;s=http://10.0.2.2:$SEED_PORT/" &
  qpid=$!
  trap 'kill $SEED_PID $qpid 2>/dev/null || true' EXIT

  wait_ssh root "$qpid"
  log "installing minimal Arch into base image"
  ssh_as root bash -s -- "$VM_USER" "'$(cat "$KEY.pub")'" <"$WS_ROOT/vm/install-base.sh"
  ssh_as root poweroff || true
  wait "$qpid" || true
  trap - EXIT
  kill "$SEED_PID" 2>/dev/null || true
  mv "$BASE.part" "$BASE"
  log "base image ready: $BASE (user $VM_USER, password 'ws')"
}

cmd_fresh() {
  [[ -f $BASE ]] || die "no base image. Run: ws vm base"
  log "resetting overlay"
  rm -f "$FRESH"
  qemu-img create -q -f qcow2 -b "$BASE" -F qcow2 "$FRESH"
  local qpid
  qemu_boot "$FRESH" &
  qpid=$!
  wait_ssh "$VM_USER" "$qpid"
  log "running boot.sh from committed repo (profile: vm)"
  ssh_vm -t 'sudo mkdir -p /mnt/ws && sudo mount -t 9p -o trans=virtio,version=9p2000.L ws /mnt/ws \
    && WS_REPO=/mnt/ws WS_PROFILE=vm bash /mnt/ws/boot.sh'
  log "install finished — 'ws vm ssh -- sudo reboot' to land in Hyprland"
  wait "$qpid"
}

cmd_run() {
  [[ -f $FRESH ]] || die "no overlay. Run: ws vm fresh"
  qemu_boot "$FRESH"
}

cmd_sync() {
  log "copying working tree into VM:~/workstation"
  tar -C "$WS_ROOT" --exclude=.vm --exclude=.git -cf - . \
    | ssh_vm 'mkdir -p ~/workstation && tar -C ~/workstation -xf -'
  ssh_vm -t '~/workstation/bin/ws install --profile vm'
}

cmd_ssh() {
  [[ ${1:-} == -- ]] && shift
  ssh_vm -t "$@"
}

main() {
  local cmd=${1:-help}
  shift || true
  case $cmd in
    check) cmd_check ;;
    base)  cmd_base ;;
    fresh) cmd_fresh ;;
    run)   cmd_run ;;
    sync)  cmd_sync ;;
    ssh)   cmd_ssh "$@" ;;
    *)     usage ;;
  esac
}

main "$@"
