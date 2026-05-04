#!/bin/bash

# ==============================================================================
# Ly Display Manager - Minimal Service Configuration
# This script follows the official documentation for systemd systems.
# ==============================================================================

set -euo pipefail

echo "--- Configuring Ly Display Manager Service ---"

# 1. Disable conflicting Display Managers
for dm in gdm sddm lightdm lxdm; do
    if systemctl is-enabled "$dm.service" &>/dev/null; then
        echo "Disabling conflicting $dm.service..."
        sudo systemctl disable "$dm.service"
    fi
done

# 2. Disable Getty on TTY2 to avoid conflicts
if systemctl is-enabled "getty@tty2.service" &>/dev/null; then
    echo "Disabling getty@tty2.service..."
    sudo systemctl disable "getty@tty2.service"
fi

# 2. Configure battery_id for laptops
if [ -f /etc/ly/config.ini ]; then
    BATTERY=$(ls /sys/class/power_supply/ | grep BAT | head -n 1 || true)
    if [ -n "$BATTERY" ]; then
        echo "Laptop detected, setting Ly battery_id to $BATTERY..."
        sudo sed -i "s/^#*battery_id = .*/battery_id = $BATTERY/" /etc/ly/config.ini
    fi
fi

# 3. Enable Ly on TTY2
echo "Enabling ly@tty2.service..."
sudo systemctl enable ly@tty2.service

# 4. Finalize
sudo systemctl daemon-reload

echo "--- Ly Service Configuration Complete! ---"
