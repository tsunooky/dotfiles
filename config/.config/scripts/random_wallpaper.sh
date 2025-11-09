#!/bin/sh

BASE_DIR="$HOME/.wallpapers"

RANDOM_IMAGE=$(find "$BASE_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | shuf -n 1)

~/.config/scripts/change_wallpaper.sh "$RANDOM_IMAGE"
