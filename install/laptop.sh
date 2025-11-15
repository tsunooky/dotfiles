#!/bin/sh

# TLP
sudo pacman -S --noconfirm --needed tlp tlp-rdw
sudo systemctl enable --now tlp.service
sudo systemctl enable NetworkManager-dispatcher.service
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket

# acpid
sudo pacman -S --noconfirm --needed acpid
sudo systemctl enable --now acpid.service
