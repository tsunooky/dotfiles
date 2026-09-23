#!/bin/bash
set -euo pipefail

if command -v yay &> /dev/null; then
    # Remove standard i3lock if installed: yay --noconfirm cannot resolve the conflict non-interactively
    if pacman -Qq i3lock &>/dev/null && ! pacman -Qq i3lock-color &>/dev/null; then
        echo "Removing conflicting standard i3lock package..."
        sudo pacman -Rdd --noconfirm i3lock
    fi

    echo "Installing i3lock-color from AUR..."
    yay -S --noconfirm --needed --answerdiff None --answerclean None i3lock-color
else
    echo "Error: yay is missing, cannot install i3lock-color."
    exit 1
fi
