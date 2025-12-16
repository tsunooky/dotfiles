#!/bin/bash
set -e

if ! command -v zsh &> /dev/null; then
    echo "Error: zsh is not installed."
    exit 1
fi

if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Changing shell to zsh for user $USER..."
    sudo chsh -s "$(which zsh)" "$USER"
else
    echo "Shell is already zsh."
fi
