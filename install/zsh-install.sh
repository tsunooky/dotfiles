#!/bin/sh

REAL_USER=${SUDO_USER:-$USER}

usermod --shell /usr/bin/zsh "$REAL_USER"

