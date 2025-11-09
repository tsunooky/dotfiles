#!/bin/sh

if [ -z "$1" ]; then
  echo "Usage: bg <path_to_wallpaper>"
  return 1
fi
if [ ! -f "$1" ]; then
  echo "Error: File not found: $1."
  return 1
fi

matugen image "$1"
feh --bg-fill "$1"
magick "$1" -blur 0x4 "$HOME/.bg_blurred.png"
