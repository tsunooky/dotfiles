#!/bin/sh

sudo pacman -S --noconfirm --needed autoconf cairo fontconfig gcc libev libjpeg-turbo libxinerama libxkbcommon-x11 libxrandr pam pkgconf xcb-util-image xcb-util-xrm

git clone https://github.com/Raymo111/i3lock-color.git /tmp/i3lock-color

cd /tmp/i3lock-color

./build.sh

./install-i3lock-color.sh

cd -

rm -rf /tmp/i3lock-color
