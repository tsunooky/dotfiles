#!/bin/bash

set -euo pipefail

echo "===> Installing Vundle plugin manager for Vim"
if [ -d ~/.vim/bundle/Vundle.vim ]; then
    echo "    Vundle already installed, skipping..."
else
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi

echo "===> Installing Vim plugins"
vim +PluginInstall +qall

echo "===> Vim plugins installed successfully"
