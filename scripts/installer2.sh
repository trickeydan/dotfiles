#! /usr/bin/env bash

HOSTNAME='arch'
KEYBOARD='uk'
LOCALE='en_GB.UTF-8'
TIMEZONE='Europe/London'
DRIVE='/dev/sda'

echo "Setting Timezone"
ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
hwclock --systohc

echo "Setting Locales"
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" >> /etc/locale.conf

echo "Setting keyboard layout"
echo "KEYMAP=$KEYBOARD" >> /etc/vconsole.conf

echo "Setting hostname"
echo "$HOSTNAME" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.0.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts
echo "::1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

echo "Editing hooks in mkinitcpio.conf"
# Removes the line starting with HOOKS
sed -i "s/^HOOKS.*//" /etc/mkinitcpio.conf
echo "HOOKS=(base udev autodetect keyboard keymap modconf block encrypt lvm2 filesystems fsck)" >> /etc/mkinitcpio.conf

echo "Generate initramfs"
mkinitcpio -p linux

echo "Set Root Password"
echo "root:secure" | chpasswd

echo "Install Bootloader"
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

echo "Modifying grub config file..."
sed -i "s/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$(blkid "$DRIVE"2 -s UUID -o value):cryptlvm root=\/dev\/secure\/root\"/g" /etc/default/grub

echo "Generate grub config..."
grub-mkconfig -o /boot/grub/grub.cfg

echo "Install Basic programs" 

pacman -S vim git python python-pipenv sudo --noconfirm
