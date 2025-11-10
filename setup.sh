#!/bin/sh

sudo pacman -Syu --no-confirm
sudo systemctl enable rfkill-unblock@all
sudo pacman -S --noconfirm --needed archlinux-keyring sed
./install/pacman.sh

sudo pacman -S --noconfirm --needed $(cat install/pkgs.txt)

./install/i3lock-color-install.sh
./install/yay-install.sh
./install/pywal-fox-install.sh
yay -S --noconfirm --answerdiff None --answerclean None matugen-bin


cp -a config/. ~/

export GTK_THEME="Adwaita:dark"
i3 reload
fc-cache -f

sudo systemctl enable NetworkManager.service
sudo systemctl start NetworkManager.service
sudo systemctl enable wpa_supplicant.service
sudo systemctl start wpa_supplicant.service

sudo systemctl --user enable --now pipewire.socket
sudo systemctl --user enable --now wireplumber.service

sudo systemctl enable --now ly.service

#alacritty & disown && exit

dunstify "Finished !" " Mod + Enter : open a terminal\n Mod + d : open dmenu"

exit
