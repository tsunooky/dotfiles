#!/bin/sh

cd ~ && git clone https://aur.archlinux.org/yay-bin.git
cd ~/yay-bin/ && makepkg -rsi --noconfirm
cd ~ && rm -Rf ~/yay-bin/

yay -Y --devel --save && yay -Y --gendb
sed -i 's/"sudoloop": false/"sudoloop": true/' ~/.config/yay/config.json;

