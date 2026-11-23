#!/usr/bin/env bash
# Test VM only: user password is "ws" and sudo needs no password.
set -euo pipefail

USERNAME=${1:?username}
PUBKEY=${2:?pubkey}
DISK=/dev/vda

echo "==> waiting for pacman keyring"
until systemctl is-active --quiet pacman-init.service; do sleep 2; done

echo "==> partitioning $DISK"
wipefs -af "$DISK"
printf 'label: dos\n,,L,*\n' | sfdisk -q "$DISK"
udevadm settle
mkfs.btrfs -q -f -L arch "${DISK}1"

echo "==> btrfs subvolumes"
mount "${DISK}1" /mnt
for sv in @ @home @log @pkg @.snapshots; do btrfs -q subvolume create "/mnt/$sv"; done
umount /mnt
opts=compress=zstd,noatime
mount -o "$opts,subvol=@" "${DISK}1" /mnt
mkdir -p /mnt/{home,var/log,var/cache/pacman/pkg,.snapshots}
mount -o "$opts,subvol=@home" "${DISK}1" /mnt/home
mount -o "$opts,subvol=@log" "${DISK}1" /mnt/var/log
mount -o "$opts,subvol=@pkg" "${DISK}1" /mnt/var/cache/pacman/pkg
mount -o "$opts,subvol=@.snapshots" "${DISK}1" /mnt/.snapshots

echo "==> pacstrap"
pacstrap -K /mnt base linux btrfs-progs grub networkmanager openssh sudo
genfstab -U /mnt >>/mnt/etc/fstab

echo "==> configuring"
arch-chroot /mnt /bin/bash -s -- "$USERNAME" "$PUBKEY" "$DISK" <<'CHROOT'
set -euo pipefail
user=$1 key=$2 disk=$3
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc
echo 'en_US.UTF-8 UTF-8' >/etc/locale.gen
locale-gen >/dev/null
echo 'LANG=en_US.UTF-8' >/etc/locale.conf
echo ws-vm >/etc/hostname

useradd -m -G wheel "$user"
echo "$user:ws" | chpasswd
echo "$user ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/ws-vm
chmod 440 /etc/sudoers.d/ws-vm
install -d -m 700 -o "$user" -g "$user" "/home/$user/.ssh"
echo "$key" >"/home/$user/.ssh/authorized_keys"
chown "$user:$user" "/home/$user/.ssh/authorized_keys"
chmod 600 "/home/$user/.ssh/authorized_keys"

grub-install --target=i386-pc "$disk" >/dev/null
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg >/dev/null
systemctl enable NetworkManager.service sshd.service
CHROOT

echo "==> done"
