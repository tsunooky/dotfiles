#!/bin/bash

set -euo pipefail

echo "===> Cloning yay-bin from AUR"
cd ~
git clone https://aur.archlinux.org/yay-bin.git

echo "===> Building yay (this may take a minute)"
cd ~/yay-bin/
makepkg -rsi --noconfirm

echo "===> Cleaning up build files"
cd ~
rm -Rf ~/yay-bin/

echo "===> Configuring yay"
yay -Y --devel --save
yay -Y --gendb

# Enable sudoloop
if [ -f ~/.config/yay/config.json ]; then
    sed -i 's/"sudoloop": false/"sudoloop": true/' ~/.config/yay/config.json
fi

echo "===> yay installed and configured successfully"

