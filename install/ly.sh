#!/bin/bash

# ==============================================================================
# Ly Display Manager Installation & Configuration Script
# ==============================================================================

set -euo pipefail

echo "--- Starting Ly Display Manager Configuration ---"

# --- 1. Installation ---
if ! pacman -Qi ly &>/dev/null; then
    echo "Installing ly..."
    sudo pacman -S --needed --noconfirm ly
else
    echo "• ly is already installed."
fi

# --- 2. Configuration ---
# We do not touch /etc/ly/config.ini to keep the system default.

# --- 3. Service Configuration ---
echo "Enabling Ly service..."
# Disable other display managers if active
for dm in gdm sddm lightdm lxdm; do
    if systemctl is-enabled "$dm.service" &>/dev/null; then
        echo "Disabling conflicting $dm..."
        sudo systemctl disable "$dm.service"
    fi
done

# Enable Ly using the standard template (TTY2 is the default for Ly on most distros)
sudo systemctl enable ly@tty2.service

# --- 4. Finalize ---
echo "Reloading systemd..."
sudo systemctl daemon-reload

echo "--- Ly Setup Complete! ---"
