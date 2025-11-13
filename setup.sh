#!/bin/sh

sudo pacman -Syu --noconfirm
sudo systemctl enable rfkill-unblock@all
sudo pacman -S --noconfirm --needed archlinux-keyring sed
./install/pacman.sh

sudo pacman -S --noconfirm --needed $(cat install/pkgs.txt)

./install/i3lock-color-install.sh
./install/yay-install.sh
./install/nv-chad-install.sh
./install/pywal-fox-install.sh
yay -S --noconfirm --answerdiff None --answerclean None matugen-bin

cp -a config/. ~/

./install/vim-install.sh 

export GTK_THEME="Adwaita:dark"
fc-cache -f

sudo systemctl enable NetworkManager.service
sudo systemctl start NetworkManager.service
sudo systemctl enable wpa_supplicant.service
sudo systemctl start wpa_supplicant.service

systemctl --user enable pipewire-pulse.service
systemctl --user enable wireplumber.service

sudo systemctl enable ly.service

chmod +x ./install/user-preferences.sh
bash ./install/user-preferences.sh

echo "#!/bin/sh
~/.config/scripts/change_wallpapers.sh ~/.wallpapers/default.jpg" > ~/.bg
chmod +x ~/.bg
