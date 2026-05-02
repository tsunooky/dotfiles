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

# --- 2. Configuration (/etc/ly/config.ini) ---
# We make the config file writable by the user so Matugen can update it.
echo "Setting up /etc/ly/config.ini permissions for Matugen..."
if [ ! -f /etc/ly/config.ini ]; then
    if [ -f /etc/ly/config.ini.example ]; then
        sudo cp /etc/ly/config.ini.example /etc/ly/config.ini
    else
        sudo touch /etc/ly/config.ini
    fi
fi

# Allow the current user to write to the config file (needed for matugen hooks)
sudo chown "$USER:$USER" /etc/ly/config.ini
sudo chmod 644 /etc/ly/config.ini

# --- 3. Service Configuration (/etc/systemd/system/ly.service) ---
echo "Creating /etc/systemd/system/ly.service from template..."

if [ -f /usr/lib/systemd/system/ly@.service ]; then
    # Copy the template, replace %i/%I with tty2, and add the Alias
    cat /usr/lib/systemd/system/ly@.service | \
        sed 's/%i/tty2/g' | \
        sed 's/%I/tty2/g' | \
        sed '/\[Install\]/a Alias=display-manager.service' | \
        sudo tee /etc/systemd/system/ly.service > /dev/null
else
    echo "⚠ Ly service template not found! Creating manual service file."
    cat <<EOF | sudo tee /etc/systemd/system/ly.service > /dev/null
[Unit]
Description=TUI display manager
After=systemd-user-sessions.service plymouth-quit-wait.service
After=getty@tty2.service
Conflicts=getty@tty2.service

[Service]
Type=idle
ExecStart=/usr/bin/ly-dm
StandardInput=tty
TTYPath=/dev/tty2
TTYReset=yes
TTYVHangup=yes

[Install]
Alias=display-manager.service
EOF
fi

# --- 4. Finalize ---
echo "Reloading systemd and enabling ly..."
sudo systemctl daemon-reload

# Disable other display managers if active
for dm in gdm sddm lightdm lxdm; do
    if systemctl is-enabled "$dm.service" &>/dev/null; then
        echo "Disabling conflicting $dm..."
        sudo systemctl disable "$dm.service"
    fi
done

# Ensure the template version is disabled to avoid TTY conflicts
if systemctl is-enabled ly@tty2.service &>/dev/null; then
    sudo systemctl disable ly@tty2.service
fi

sudo systemctl enable ly.service

echo "--- Ly Setup Complete! ---"
