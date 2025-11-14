#!/bin/bash

set -euo pipefail

echo "===> Cloning yay-bin from AUR"
cd ~
if [ -d ~/yay-bin ]; then
    rm -rf ~/yay-bin
fi
git clone https://aur.archlinux.org/yay-bin.git

echo "===> Building yay (this may take a minute)"
cd ~/yay-bin/

echo "===> Running makepkg"
# Use --noconfirm and redirect stdin to avoid blocking
makepkg -si --noconfirm --needed < /dev/null

echo "===> Cleaning up build files"
cd ~
rm -rf ~/yay-bin/

echo "===> Configuring yay"
# Run yay commands with proper input handling
yay -Y --devel --save < /dev/null || true
yay -Y --gendb < /dev/null || true

# Enable sudoloop
if [ -f ~/.config/yay/config.json ]; then
    sed -i 's/"sudoloop": false/"sudoloop": true/' ~/.config/yay/config.json
fi

echo "===> yay installed and configured successfully"

