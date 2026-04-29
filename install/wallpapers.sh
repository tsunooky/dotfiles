#!/bin/bash

# ==============================================================================
# Wallpaper Download & Setup Script (Follows epidots pattern)
# ==============================================================================

set -euo pipefail

REPO_WALLPAPER="https://github.com/tsunooky/epidots-wallpapers.git"
WALLPAPERS_DIR="$HOME/.wallpapers"

echo "--- Downloading Default Wallpapers from epidots-wallpapers ---"

# Ensure git is available (should be installed by main setup, but safety first)
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed. Cannot download wallpapers."
    exit 1
fi

if [ ! -d "$WALLPAPERS_DIR" ]; then
    echo "Cloning wallpapers into $WALLPAPERS_DIR..."
    if git clone "$REPO_WALLPAPER" "$WALLPAPERS_DIR"; then
        # Removing .git to keep it as a simple directory, following epidots convention
        rm -rf "$WALLPAPERS_DIR/.git"
        echo "Wallpapers successfully downloaded."
    else
        echo "Failed to clone wallpapers repository."
        exit 1
    fi
else
    echo "Wallpapers directory already exists ($WALLPAPERS_DIR). Skipping download to avoid overwrite."
fi

echo "--- Wallpaper Setup Complete! ---"
