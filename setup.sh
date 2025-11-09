#!/bin/sh

sudo pacman -Syu
sudo pacman -Syu --noconfirm --needed $(cat install/pkgs.txt)

./install/i3lock-color-install.sh

cp -a config/. ~/

i3 reload

dunstify "Finished !" " Mod + Enter : open a terminal\n Mod + d : open dmenu"

exit
