#! /usr/bin/env bash

# Variables

DRIVE="/dev/sda"

# Functions

function die {
	echo "Error: $1"
	exit 1
}


# System Checks

# Check keymap is valid

if [ ! -d /sys/firmware/efi/efivars ]; then
	die "The system doesn't seem to be booted in EFI mode."
fi

ping -c1 google.co.uk 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	die "Unable to contact the internet."
fi

if [[ $EUID -ne 0 ]]; then
   die "This script must be run as root"
fi

# Check drive exists

# Installation 

die "End of Script"

echo "Set up Locale for Installer"
loadkeys uk
timedatectl set-ntp true

echo "Partitioning target drive with GPT, 600MiB EFI boot, LVM..."
parted -s "$DRIVE" mklabel gpt \
mkpart ESP fat32 1MiB 600MiB set 1 esp on \
mkpart primary ext4 600MiB 100% set 2 LVM on

echo "Configuring Full Disk Encryption" 

echo -n "secure" > keyfile
cryptsetup -c aes-xts-plain64 -s 512 -h sha512 -i 16384 -d keyfile luksFormat --type luks2 --batch-mode "$DRIVE"2
cryptsetup open "$DRIVE"2 cryptlvm -d keyfile

echo "Configuring LVM"
pvcreate /dev/mapper/cryptlvm
vgcreate secure /dev/mapper/cryptlvm

echo "Creating LVM Volumes"

lvcreate -L 16G secure -n swap
lvcreate -L 64G secure -n root
lvcreate -L 32G secure -n var
lvcreate -l 100%FREE secure -n home

echo "Creating filesystems"
mkswap /dev/secure/swap
mkfs.ext4 /dev/secure/root
mkfs.ext4 /dev/secure/var
mkfs.ext4 /dev/secure/home

echo "Creating boot filesystem"
mkfs.fat -F32 "$DRIVE"1

echo "Mounting filesystems"
mount /dev/secure/root /mnt
mkdir /mnt/var /mnt/home /mnt/boot
mount /dev/secure/var /mnt/var
mount /dev/secure/home /mnt/home
mount "$DRIVE"1 /mnt/boot
swapon /dev/secure/swap

echo "Fetching Fastest mirrors"
curl "https://www.archlinux.org/mirrorlist/?country=GB&protocol=https&ip_version=4&ip_version=6&use_mirror_status=on"
sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist

echp "Installing Base Packages"
pacstrap /mnt base

echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

