#!/bin/bash
set -euo pipefail

if command -v yay &> /dev/null; then
    echo "yay is already installed."
    exit 0
fi

if ! command -v git &> /dev/null; then
    echo "Error: git is required to install yay."
    exit 1
fi

if ! command -v makepkg &> /dev/null; then
    echo "Error: makepkg is required to install yay."
    exit 1
fi

TEMP_DIR=$(mktemp -d)
echo "Building yay in $TEMP_DIR..."

# Ensure cleanup on failure
trap 'rm -rf "$TEMP_DIR"' EXIT

git clone https://aur.archlinux.org/yay-bin.git "$TEMP_DIR/yay-bin"
cd "$TEMP_DIR/yay-bin"

makepkg -rsi --noconfirm

# Configure yay
yay -Y --devel --save
yay -Y --gendb

mkdir -p ~/.config/yay
if [ -f ~/.config/yay/config.json ]; then
    sed -i 's/"sudoloop": false/"sudoloop": true/' ~/.config/yay/config.json
fi

echo "yay installed successfully."
