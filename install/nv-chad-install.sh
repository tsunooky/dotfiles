#!/bin/bash

set -euo pipefail

echo "===> Installing NvChad dependencies"
sudo pacman -S --noconfirm --needed ripgrep python python-pywal python-watchdog gcc make

echo "===> Backing up existing Neovim configuration"
rm -rf ~/.config/nvim.bak 2>/dev/null || true
if [ -d ~/.config/nvim ]; then
    mv ~/.config/nvim ~/.config/nvim.bak
    echo "    Existing config backed up to ~/.config/nvim.bak"
fi

rm -rf ~/.local/state/nvim
rm -rf ~/.local/share/nvim

echo "===> Cloning NvChad starter configuration"
git clone https://github.com/NvChad/starter ~/.config/nvim

echo "===> Cloning NvChad pywal integration"
git clone https://github.com/NvChad/pywal ~/.config/nvim/pywal

echo "===> Configuring pywal integration"
echo '

os.execute("python ~/.config/nvim/pywal/chadwal.py &> /dev/null &")

local autocmd = vim.api.nvim_create_autocmd

autocmd("Signal", {
  pattern = "SIGUSR1",
  callback = function()
    require("nvchad.utils").reload()
  end
})

' >> ~/.config/nvim/init.lua

echo "===> Installing plugins (this may take a few minutes)"
nvim --headless "+Lazy! sync" "+MasonInstallAll" +qa

echo "===> Setting chadwal theme"
sed -i '/M.base46 = {/,/}/ s/theme = .*,/theme = "chadwal",/' ~/.config/nvim/lua/chadrc.lua

echo "===> NvChad installed successfully"

rm -rf ~/.config/nvim/.git

