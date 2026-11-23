#!/usr/bin/env bash
# VM harness: test a full install without touching the real machine.
#
#   base.qcow2   clean Arch after archinstall (built once, by hand: `ws vm base`)
#   fresh.qcow2  throwaway overlay on top of base; `ws vm fresh` resets it
#
# Runs on any Linux host with KVM + QEMU (works from the current Ubuntu box).
set -euo pipefail

WS_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
source "$WS_ROOT/lib/common.sh"

VM_DIR=${WS_VM_DIR:-$WS_ROOT/.vm}
BASE=$VM_DIR/base.qcow2
FRESH=$VM_DIR/fresh.qcow2
ISO=$VM_DIR/archlinux.iso
SSH_PORT=${WS_VM_SSH_PORT:-2222}
VM_USER=${WS_VM_USER:-$USER}
MEM=${WS_VM_MEM:-8G}
CPUS=${WS_VM_CPUS:-4}
DISK_SIZE=${WS_VM_DISK:-40G}

usage() {
  cat <<USAGE
usage: ws vm <command>

  check    verify KVM / QEMU / GL on this host
  base     download Arch ISO, create base disk, boot installer (one-time, manual)
  fresh    reset overlay to clean base, boot, run boot.sh from committed repo
  run      boot the current overlay as-is (keeps state)
  sync     copy working tree (incl. uncommitted) into running VM, run ws install
  ssh      shell into running VM
USAGE
}

ssh_vm() {
  ssh -p "$SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o LogLevel=ERROR "$VM_USER@localhost" "$@"
}

wait_ssh() {
  log "waiting for ssh on :$SSH_PORT"
  local i
  for i in $(seq 1 120); do
    ssh_vm -o ConnectTimeout=2 true 2>/dev/null && return 0
    sleep 2
  done
  die "VM did not come up on ssh"
}

cmd_check() {
  local ok=1
  if [[ -e /dev/kvm ]]; then info "kvm: ok"
  else warn "/dev/kvm missing — enable VT-x/AMD-V (SVM) in BIOS"; ok=0; fi
  if [[ -r /dev/kvm && -w /dev/kvm ]] || [[ ! -e /dev/kvm ]]; then :
  else warn "no access to /dev/kvm — add yourself to the kvm group"; ok=0; fi
  have qemu-system-x86_64 && info "qemu: ok" || { warn "qemu-system-x86_64 missing"; ok=0; }
  have qemu-img && info "qemu-img: ok" || { warn "qemu-img missing"; ok=0; }
  ((ok)) && log "host ready" || die "host not ready"
}

# Boot a disk. Extra args are appended (e.g. -cdrom).
qemu_boot() {
  local disk=$1; shift
  qemu-system-x86_64 \
    -enable-kvm -cpu host -smp "$CPUS" -m "$MEM" \
    -drive file="$disk",if=virtio,format=qcow2 \
    -nic user,model=virtio-net-pci,hostfwd=tcp::"$SSH_PORT"-:22 \
    -device virtio-vga-gl -display gtk,gl=on \
    -device qemu-xhci -device usb-tablet \
    -audiodev pipewire,id=snd0 -device ich9-intel-hda -device hda-output,audiodev=snd0 \
    -virtfs local,path="$WS_ROOT",mount_tag=ws,security_model=none,readonly=on \
    "$@"
}

cmd_base() {
  cmd_check
  mkdir -p "$VM_DIR"
  if [[ ! -f $ISO ]]; then
    log "downloading Arch ISO"
    curl -fL -o "$ISO" https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso
  fi
  [[ -f $BASE ]] && die "$BASE exists. Delete it to rebuild."
  qemu-img create -f qcow2 "$BASE" "$DISK_SIZE"
  cat <<MSG

In the installer:
  1. archinstall — bootloader: grub (BIOS), network: NetworkManager,
     user: $VM_USER with sudo, filesystem: btrfs (default subvolumes),
     profile: minimal, extra packages: openssh
  2. reboot into the installed system, log in, then:
       sudo systemctl enable --now sshd
       echo '$VM_USER ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/ws-vm
       mkdir -p ~/.ssh && echo '<your host pubkey>' >> ~/.ssh/authorized_keys
  3. sudo poweroff — base.qcow2 is now the clean snapshot.

MSG
  qemu_boot "$BASE" -cdrom "$ISO" -boot once=d
}

cmd_fresh() {
  [[ -f $BASE ]] || die "no base image. Run: ws vm base"
  log "resetting overlay"
  rm -f "$FRESH"
  qemu-img create -q -f qcow2 -b "$BASE" -F qcow2 "$FRESH"
  qemu_boot "$FRESH" &
  local qpid=$!
  wait_ssh
  log "running boot.sh from committed repo (profile: vm)"
  ssh_vm -t 'sudo mkdir -p /mnt/ws && sudo mount -t 9p -o trans=virtio,version=9p2000.L ws /mnt/ws \
    && WS_REPO=/mnt/ws WS_PROFILE=vm bash /mnt/ws/boot.sh'
  log "install finished — reboot the VM to land in Hyprland (ws vm ssh -- sudo reboot)"
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
