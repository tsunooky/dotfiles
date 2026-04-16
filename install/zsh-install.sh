#!/bin/bash
set -euo pipefail

if ! command -v zsh &> /dev/null; then
    echo "Error: zsh is not installed."
    exit 1
fi

REAL_USER=${SUDO_USER:-$USER}
sudo usermod --shell /usr/bin/zsh "$REAL_USER"
exit 0
