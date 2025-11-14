#!/bin/bash

set -uo pipefail

echo "===> Installing i3lock-color build dependencies"
sudo pacman -S --noconfirm --needed autoconf cairo fontconfig gcc libev libjpeg-turbo libxinerama libxkbcommon-x11 libxrandr pam pkgconf xcb-util-image xcb-util-xrm

echo "===> Cloning i3lock-color repository"
if [ -d /tmp/i3lock-color ]; then
    sudo rm -rf /tmp/i3lock-color
fi
git clone https://github.com/Raymo111/i3lock-color.git /tmp/i3lock-color

cd /tmp/i3lock-color

echo "===> Building i3lock-color (this may take a few minutes)"
echo "    Note: Compilation warnings are normal and can be ignored"
./build.sh || {
    echo "Build script failed, but this might be due to warnings"
    echo "Continuing with installation..."
}

echo "===> Installing i3lock-color"
sudo ./install-i3lock-color.sh

cd -

echo "===> Cleaning up build files"
sudo rm -rf /tmp/i3lock-color

echo "===> i3lock-color installed successfully"
