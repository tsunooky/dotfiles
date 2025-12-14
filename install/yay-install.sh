#!/bin/sh

rm -rf ~/yay-bin

cd ~ && git clone https://aur.archlinux.org/yay-bin.git
cd ~/yay-bin/ && makepkg -rsi --noconfirm
cd ~ && rm -Rf ~/yay-bin/

yay -Y --devel --save && yay -Y --gendb
mkdir -p ~/.config/yay
sed -i 's/"sudoloop": false/"sudoloop": true/' ~/.config/yay/config.json;
