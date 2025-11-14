#!/bin/bash

set -euo pipefail

echo "===> Installing i3lock-color build dependencies"
sudo pacman -S --noconfirm --needed autoconf cairo fontconfig gcc libev libjpeg-turbo libxinerama libxkbcommon-x11 libxrandr pam pkgconf xcb-util-image xcb-util-xrm

echo "===> Cloning i3lock-color repository"
git clone https://github.com/Raymo111/i3lock-color.git /tmp/i3lock-color

cd /tmp/i3lock-color

echo "===> Building i3lock-color (this may take a few minutes)"
./build.sh

echo "===> Installing i3lock-color"
sudo ./install-i3lock-color.sh

cd -

echo "===> Cleaning up build files"
rm -rf /tmp/i3lock-color

echo "===> i3lock-color installed successfully"
