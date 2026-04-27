#!/bin/bash

# ==============================================================================
# General GRUB & Dual-Boot Setup Script (Arch Linux)
# ==============================================================================

set -euo pipefail

# --- Configuration ---
LOG_FILE="/var/log/grub-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "--- Starting General GRUB & Dual-Boot Configuration ---"

# --- 0. GRUB Detection ---
# We check if /etc/default/grub exists and if grub-mkconfig is available.
# This prevents errors on systems using other bootloaders (like systemd-boot).
if [ ! -f /etc/default/grub ] || ! command -v grub-mkconfig &> /dev/null; then
    echo "• GRUB not detected or not used. Skipping GRUB configuration."
    exit 0
fi

# --- 1. GRUB Configuration (Timeout, Style & Resolution) ---
echo "Configuring GRUB defaults..."

if [ -f /etc/default/grub ]; then
    # Backup original
    [ ! -f /etc/default/grub.bak ] && sudo cp /etc/default/grub /etc/default/grub.bak

    # Enable os-prober
    if ! grep -q "GRUB_DISABLE_OS_PROBER=false" /etc/default/grub; then
        echo "Enabling os-prober in GRUB..."
        if grep -q "GRUB_DISABLE_OS_PROBER" /etc/default/grub; then
            sudo sed -i 's/GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
        else
            echo 'GRUB_DISABLE_OS_PROBER=false' | sudo tee -a /etc/default/grub
        fi
    fi

    # Timeout and Style
    echo "Setting GRUB timeout to 8 seconds..."
    sudo sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=8/' /etc/default/grub
    sudo sed -i 's/GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/' /etc/default/grub
    
    if grep -q "GRUB_RECORDFAIL_TIMEOUT" /etc/default/grub; then
        sudo sed -i 's/GRUB_RECORDFAIL_TIMEOUT=.*/GRUB_RECORDFAIL_TIMEOUT=8/' /etc/default/grub
    else
        echo 'GRUB_RECORDFAIL_TIMEOUT=8' | sudo tee -a /etc/default/grub
    fi

    # Kernel Parameters for clean "Pro" boot
    # loglevel=3 hides non-critical errors, systemd.show_status=true shows the [ OK ] messages
    echo "Configuring clean boot kernel parameters..."
    # We remove 'quiet' and add our preferred params
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)quiet\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1\2"/' /etc/default/grub
    # Ensure loglevel=3 and systemd.show_status=true are present
    if ! grep -q "loglevel=3" /etc/default/grub; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 /' /etc/default/grub
    fi
    if ! grep -q "systemd.show_status=true" /etc/default/grub; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="systemd.show_status=true /' /etc/default/grub
    fi
    # Cleanup double spaces
    sudo sed -i 's/  */ /g' /etc/default/grub

    # Resolution handling
    DETECTOR_RES="1024x768x32"
    if command -v xrandr &> /dev/null; then
        CURRENT_RES=$(xrandr | grep '*' | awk '{print $1}' | head -n 1 || true)
        if [ -n "$CURRENT_RES" ]; then
            WIDTH=$(echo "$CURRENT_RES" | cut -d'x' -f1)
            # If 4K or higher, use 1080p for better readability in GRUB
            if [ "$WIDTH" -ge 3840 ]; then
                DETECTOR_RES="1920x1080x32"
            else
                DETECTOR_RES="${CURRENT_RES}x32"
            fi
        fi
    fi

    echo "Setting GRUB resolution to $DETECTOR_RES..."
    sudo sed -i "s/GRUB_GFXMODE=.*/GRUB_GFXMODE=$DETECTOR_RES/" /etc/default/grub
    
    if ! grep -q "GRUB_GFXPAYLOAD_LINUX" /etc/default/grub; then
        echo 'GRUB_GFXPAYLOAD_LINUX=keep' | sudo tee -a /etc/default/grub
    fi
    
    sudo sed -i 's/GRUB_TERMINAL_OUTPUT=.*/GRUB_TERMINAL_OUTPUT=gfxterm/' /etc/default/grub

    # --- Theme Installation (Vimix Very Dark Blue) ---
    echo "Installing Vimix Very Dark Blue theme..."
    THEME_NAME="grub-theme-vimix-very-dark-blue"
    THEME_PATH="/usr/share/grub/themes/$THEME_NAME/theme.txt"

    if command -v yay &> /dev/null; then
        yay -S --needed --noconfirm "$THEME_NAME"
    else
        echo "yay not found, installing theme manually..."
        sudo mkdir -p "/usr/share/grub/themes/$THEME_NAME"
        TMP_THEME_DIR=$(mktemp -d)
        git clone "https://github.com/trueNAHO/grub2-theme-vimix-very-dark-blue.git" "$TMP_THEME_DIR"
        sudo cp -r "$TMP_THEME_DIR/src/." "/usr/share/grub/themes/$THEME_NAME/"
        rm -rf "$TMP_THEME_DIR"
    fi

    if [ -f "$THEME_PATH" ]; then
        echo "Activating theme in /etc/default/grub..."
        if grep -q "^GRUB_THEME=" /etc/default/grub; then
            sudo sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"$THEME_PATH\"|" /etc/default/grub
        else
            echo "GRUB_THEME=\"$THEME_PATH\"" | sudo tee -a /etc/default/grub
        fi
        # Comment out background if it exists to avoid conflicts with theme
        sudo sed -i 's/^GRUB_BACKGROUND=/#GRUB_BACKGROUND=/' /etc/default/grub
    fi
fi

# --- 2. Dual-Boot Detection (Windows EFI) ---
echo "Attempting to detect Windows EFI partition..."

find_win_efi() {
    # Check all vfat partitions
    for part in $(lsblk -lno NAME,FSTYPE | grep vfat | awk '{print "/dev/"$1}'); do
        # Skip if already mounted at /boot or /efi (Arch's own ESP)
        if mountpoint -q /boot && [ "$(findmnt -nvo SOURCE /boot)" = "$part" ]; then continue; fi
        if mountpoint -q /efi && [ "$(findmnt -nvo SOURCE /efi)" = "$part" ]; then continue; fi
        
        # Try mounting to check content
        TMP_MNT=$(mktemp -d)
        if sudo mount -o ro "$part" "$TMP_MNT" 2>/dev/null; then
            if [ -f "$TMP_MNT/EFI/Microsoft/Boot/bootmgfw.efi" ]; then
                sudo umount "$TMP_MNT"
                rmdir "$TMP_MNT"
                echo "$part"
                return 0
            fi
            sudo umount "$TMP_MNT"
        fi
        rmdir "$TMP_MNT"
    done
    return 1
}

WIN_EFI_PART=$(find_win_efi || true)

if [ -n "$WIN_EFI_PART" ]; then
    echo "Found Windows EFI partition: $WIN_EFI_PART"
    sudo mkdir -p /mnt/win_efi
    if ! mountpoint -q /mnt/win_efi; then
        # Mounting as read-only (-o ro) for absolute safety
        sudo mount -o ro "$WIN_EFI_PART" /mnt/win_efi || echo "Failed to mount $WIN_EFI_PART"
    fi
else
    echo "No distinct Windows EFI partition found. os-prober will search mounted filesystems."
fi

# --- 3. Finalize ---
echo "Installing tools for detection..."
sudo pacman -S --needed --noconfirm os-prober ntfs-3g

echo "Updating GRUB configuration..."
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Cleanup
if mountpoint -q /mnt/win_efi; then
    sudo umount /mnt/win_efi
fi

echo "--- General GRUB Setup Complete! ---"
