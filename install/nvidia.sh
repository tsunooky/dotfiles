#!/bin/bash

# ==============================================================================
# NVIDIA Setup Script (Arch Linux)
# Optimized for GTX 900 series (Maxwell) to RTX 5000+ series (2026)
# ==============================================================================

set -euo pipefail

# --- Configuration ---
LOG_FILE="/var/log/nvidia-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "--- Starting NVIDIA Configuration ---"

# --- Functions ---

# Function to check if a package is installed
is_installed() {
    pacman -Qi "$1" &> /dev/null
}

# --- 1. GPU Detection ---
GPU_INFO=$(lspci | grep -i nvidia || true)
if [ -z "$GPU_INFO" ]; then
    echo "No NVIDIA GPU detected. Skipping NVIDIA-specific setup."
    exit 0
fi

echo "Detected NVIDIA GPU: $GPU_INFO"

# Check for 900 series (Maxwell) which might need legacy drivers in 2026
IS_LEGACY=false
if echo "$GPU_INFO" | grep -qiE "GTX (950|960|970|980|Titan X)"; then
    echo "Identified Maxwell (900 series) GPU. Using legacy-compatible branch."
    IS_LEGACY=true
fi

# --- 2. Enable Multilib (required for lib32 packages) ---
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo "Enabling multilib repository..."
    sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf
    sudo pacman -Syu
fi

# --- 3. Install Dependencies & Drivers ---
echo "Installing linux-headers and base-devel..."
sudo pacman -S --needed --noconfirm linux-headers base-devel

if [ "$IS_LEGACY" = true ]; then
    # Based on user requirement for 2026: nvidia-550xx-dkms
    DRIVER_PKG="nvidia-550xx-dkms"
    UTILS_PKG="nvidia-550xx-utils"
    LIB32_PKG="lib32-nvidia-550xx-utils"
else
    DRIVER_PKG="nvidia-dkms"
    UTILS_PKG="nvidia-utils"
    LIB32_PKG="lib32-nvidia-utils"
fi

echo "Installing $DRIVER_PKG and related packages..."
if command -v yay &> /dev/null; then
    yay -S --needed --noconfirm "$DRIVER_PKG" "$UTILS_PKG" "$LIB32_PKG" nvidia-settings
else
    echo "yay not found. Attempting to use pacman..."
    sudo pacman -S --needed --noconfirm "$DRIVER_PKG" "$UTILS_PKG" "$LIB32_PKG" nvidia-settings || echo "Failed to install via pacman. Please install yay first."
fi

# --- 4. Early KMS Configuration ---
echo "Configuring Early KMS in /etc/mkinitcpio.conf..."
if [ -f /etc/mkinitcpio.conf ]; then
    if ! grep -q "nvidia nvidia_modeset nvidia_uvm nvidia_drm" /etc/mkinitcpio.conf; then
        sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
        sudo sed -i 's/  */ /g' /etc/mkinitcpio.conf
    fi
fi

echo "Rebuilding initramfs..."
sudo mkinitcpio -P

# --- 5. Kernel Parameters (nvidia-drm.modeset=1) ---
if [ -f /etc/default/grub ]; then
    if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
        echo "Adding nvidia-drm.modeset=1 to GRUB command line..."
        # We append it to existing params, ensuring we don't duplicate or mess with others
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 /' /etc/default/grub
        echo "Updating GRUB configuration to apply kernel parameters..."
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
fi

echo "--- NVIDIA Setup Complete! ---"
