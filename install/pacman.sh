#!/bin/bash

set -euo pipefail

echo "Configuring pacman..."

# Backup original config
if [ ! -f /etc/pacman.conf.backup ]; then
    sudo cp /etc/pacman.conf /etc/pacman.conf.backup
fi

# Remove any existing ILoveCandy line
sudo sed -i '/ILoveCandy/d' /etc/pacman.conf

# Add ILoveCandy under [options]
sudo sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf

# Enable Color
sudo sed -i 's/#Color/Color/' /etc/pacman.conf

# Enable parallel downloads
sudo sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

# Enable multilib (for 32-bit support)
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo "" | sudo tee -a /etc/pacman.conf
    echo "[multilib]" | sudo tee -a /etc/pacman.conf
    echo "Include = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
fi

# Update package database
sudo pacman -Sy

echo "Pacman configured successfully"
