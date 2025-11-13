sudo pacman -S --noconfirm --needed git
git clone https://github.com/tsunooky/dotfiles.git /tmp/config
cd /tmp/config
./setup.sh
cd -
rm -rf /tmp/config

echo "end"
sudo reboot
