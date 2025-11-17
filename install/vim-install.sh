#!/bin/sh

sudo pacman -S --noconfirm --needed vim

mkdir -p ~/.vim/bundle

if [ ! -d ~/.vim/bundle/Vundle.vim ]; then
  git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
else
  echo "Vundle is already cloned."
fi

vim +PluginInstall +qall
