#!/bin/bash
set -e

if command -v yay &> /dev/null; then
    echo "yay is already installed."
    exit 0
fi

TEMP_DIR=$(mktemp -d)
echo "Building yay in $TEMP_DIR..."

git clone https://aur.archlinux.org/yay-bin.git "$TEMP_DIR/yay-bin"
cd "$TEMP_DIR/yay-bin"

makepkg -rsi --noconfirm

yay -Y --devel --save
yay -Y --gendb

mkdir -p ~/.config/yay
if [ -f ~/.config/yay/config.json ]; then
    sed -i 's/"sudoloop": false/"sudoloop": true/' ~/.config/yay/config.json
fi

cd ~
rm -rf "$TEMP_DIR"
