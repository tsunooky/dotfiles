#!/bin/sh

REAL_USER=${SUDO_USER:-$USER}

sudo usermod --shell /usr/bin/zsh "$REAL_USER"

exit 0
