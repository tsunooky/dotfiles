#!/bin/sh

if [ -z "$1" ]; then
  echo "Usage: bg <path_to_wallpaper>"
  exit 1
fi
if [ ! -f "$1" ]; then
  echo "Error: File not found: $1."
  exit 1
fi

i3 workspace 42 > /dev/null
sleep 0.1
matugen image "$1"
echo "$1" > ~/.curbg
feh --bg-fill "$1"
sleep 0.5
i3 workspace back_and_forth > /dev/null
