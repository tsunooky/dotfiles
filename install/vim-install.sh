#!/bin/bash
set -e

if ! command -v vim &> /dev/null; then
    sudo pacman -S --noconfirm --needed vim
fi

BUNDLE_DIR="$HOME/.vim/bundle/Vundle.vim"

if [ ! -d "$BUNDLE_DIR" ]; then
    echo "Cloning Vundle..."
    mkdir -p "$HOME/.vim/bundle"
    git clone https://github.com/VundleVim/Vundle.vim.git "$BUNDLE_DIR"
else
    echo "Vundle already installed."
fi

echo "Installing Vim plugins..."
vim +PluginInstall +qall > /dev/null 2>&1
