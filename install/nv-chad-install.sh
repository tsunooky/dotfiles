#!/bin/sh

sudo pacman -S --no-confirm --needed ripgrep python python-pywal python-watchdog neovim gcc make

rm -rf ~/.config/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.local/share/nvimi

git clone https://github.com/NvChad/starter ~/.config/nvim
git clone https://github.com/NvChad/pywal ~/.config/nvim/pywal

echo '

os.execute("python ~/.config/nvim/pywal/chadwal.py &> /dev/null &")

local autocmd = vim.api.nvim_create_autocmdautocmd("Signal", {

  pattern = "SIGUSR1",
  callback = function()
    require("nvchad.utils").reload()
  end
})

' >> ~/.config/nvim/init.lua

nvim --headless "+Lazy! sync" "+MasonInstallAll" +qa

sed -i '/M.base46 = {/,/}/ s/theme = .*,/theme = "chadwal",/' ~/.config/nvim/lua/custom/chadrc.lua

rm -rf ~/.config/nvim/.git

