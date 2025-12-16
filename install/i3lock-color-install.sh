#!/bin/bash
set -e

if command -v yay &> /dev/null; then
    echo "Installing i3lock-color from AUR..."
    yay -S --noconfirm --needed i3lock-color
else
    echo "Error: yay is missing, cannot install i3lock-color."
    exit 1
fi
