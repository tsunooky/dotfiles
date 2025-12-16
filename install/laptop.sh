#!/bin/bash
set -e

echo "Installing Laptop tools..."

sudo pacman -S --noconfirm --needed tlp tlp-rdw
sudo systemctl enable --now tlp.service
sudo systemctl enable NetworkManager-dispatcher.service

sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket

sudo pacman -S --noconfirm --needed acpid
sudo systemctl enable --now acpid.service

echo "Laptop optimizations applied."
