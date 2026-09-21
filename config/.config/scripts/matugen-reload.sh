#!/bin/sh
# Renders every matugen template (colors, dunst, flameshot, lock.sh...) from an
# image and runs the post hooks. Defaults to the current wallpaper (~/.curbg).
# Used by change_wallpaper.sh, edit_config.sh and the dotfiles installer.

IMAGE="${1:-$(cat ~/.curbg 2>/dev/null)}"

if [ -z "$IMAGE" ] || [ ! -f "$IMAGE" ]; then
    echo "matugen-reload: no wallpaper to render from (${IMAGE:-~/.curbg missing})" >&2
    exit 1
fi

VERSION=$(matugen --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | cut -d. -f1)

if [ "${VERSION:-0}" -ge 4 ]; then
    matugen image "$IMAGE" --old-json-output --source-color-index 0
else
    matugen image "$IMAGE"
fi
