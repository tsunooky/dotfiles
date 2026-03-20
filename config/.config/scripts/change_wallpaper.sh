#!/bin/sh


run_matugen() {
    local IMAGE_PATH="$1"

    if [ -z "$IMAGE_PATH" ]; then
        echo "Erreur : Tu dois spécifier le chemin d'une image."
        return 1
    fi

    local VERSION=$(matugen --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | cut -d. -f1)

    if [ "$VERSION" -ge 4 ]; then
        matugen image "$IMAGE_PATH" --old-json-output --source-color-index 0
    else
        matugen image "$IMAGE_PATH"
    fi
}


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
run_matugen "$1"
echo "$1" > ~/.curbg
feh --bg-fill "$1"
sleep 0.5
i3 workspace back_and_forth > /dev/null
