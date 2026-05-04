#!/bin/bash

# ==============================================================================
# Smart Bootloader & Dual-Boot Setup Script
# Supports UEFI/BIOS and Single/Multi-disk Dual Boot
# Keeps systemd-boot if no dual-boot is detected
# ==============================================================================

set -euo pipefail

# --- Configuration ---
LOG_FILE="/var/log/grub-setup.log"
sudo touch "$LOG_FILE" && sudo chmod 666 "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "--- Starting Bootloader Configuration ---"

# --- 0. Detection Helpers ---

is_uefi() {
    [ -d /sys/firmware/efi ]
}

is_systemd_boot() {
    # Check if bootctl is installed and reports an active status
    if command -v bootctl &>/dev/null; then
        if bootctl status 2>/dev/null | grep -q "bootloader-id: systemd-boot"; then
            return 0
        fi
    fi
    # Alternative: check for loader.conf in common EFI locations
    for dir in /boot /efi /boot/efi; do
        if [ -f "$dir/loader/loader.conf" ]; then return 0; fi
    done
    return 1
}

get_efi_dir() {
    for dir in /boot /efi /boot/efi; do
        if mountpoint -q "$dir" && [ -d "$dir/EFI" ]; then
            echo "$dir"
            return 0
        fi
    done
    local esp_mount
    esp_mount=$(findmnt -no TARGET -t vfat | head -n 1)
    if [ -n "$esp_mount" ] && [ -d "$esp_mount/EFI" ]; then
        echo "$esp_mount"
        return 0
    fi
    return 1
}

# --- 1. Dual-Boot Scan ---

echo "• Scanning for other operating systems..."
TEMP_MOUNTS="/tmp/grub_temp_mounts"
rm -f "$TEMP_MOUNTS" && touch "$TEMP_MOUNTS"

find_windows() {
    local found=0
    # Scan all partitions with vfat/ntfs
    lsblk -lno NAME,FSTYPE,MOUNTPOINT | grep -E "vfat|ntfs" | while read -r name fstype mnt; do
        dev="/dev/$name"
        # Skip if it's our current EFI/Root to avoid recursive mounting
        if [ -n "$mnt" ] && { [ "$mnt" = "/boot" ] || [ "$mnt" = "/efi" ] || [ "$mnt" = "/" ]; }; then
             # Still check the content if it's already mounted
             if [ -f "$mnt/EFI/Microsoft/Boot/bootmgfw.efi" ] || [ -f "$mnt/bootmgr" ]; then
                return 0
             fi
             continue
        fi
        
        tmp_mnt=$(mktemp -d)
        if sudo mount -o ro "$dev" "$tmp_mnt" 2>/dev/null; then
            if [ -f "$tmp_mnt/EFI/Microsoft/Boot/bootmgfw.efi" ] || [ -f "$tmp_mnt/bootmgr" ]; then
                echo "$tmp_mnt" >> "$TEMP_MOUNTS"
                found=1
            else
                sudo umount "$tmp_mnt"
                rmdir "$tmp_mnt"
            fi
        else
            rmdir "$tmp_mnt"
        fi
    done
    [ -s "$TEMP_MOUNTS" ] && return 0 || return 1
}

WINDOWS_FOUND=0
if find_windows; then
    WINDOWS_FOUND=1
    echo "✓ Windows detected!"
fi

# --- 2. Strategy Decision ---

SHOULD_INSTALL_GRUB=0

if [ "$WINDOWS_FOUND" -eq 1 ]; then
    echo "• Dual-boot detected: GRUB is required."
    SHOULD_INSTALL_GRUB=1
elif [ -d "/boot/grub" ] || [ -f "/etc/default/grub" ]; then
    echo "• GRUB already seems to be the active bootloader."
    SHOULD_INSTALL_GRUB=1
elif is_systemd_boot; then
    echo "• systemd-boot detected and no Windows found. Skipping GRUB installation."
    # Cleanup mounts before exiting
    while read -r mnt; do sudo umount "$mnt"; rmdir "$mnt"; done < "$TEMP_MOUNTS"
    exit 0
else
    echo "• No specific bootloader configuration detected. Installing GRUB as default."
    SHOULD_INSTALL_GRUB=1
fi

# --- 3. GRUB Installation & Config ---

if [ "$SHOULD_INSTALL_GRUB" -eq 1 ]; then
    echo "• Proceeding with GRUB configuration..."
    sudo pacman -S --needed --noconfirm grub efibootmgr os-prober ntfs-3g

    if is_uefi; then
        EFI_DIR=$(get_efi_dir || true)
        if [ -n "$EFI_DIR" ]; then
            sudo grub-install --target=x86_64-efi --efi-directory="$EFI_DIR" --bootloader-id=GRUB --recheck
        fi
    else
        BOOT_DISK=$(lsblk -no PKNAME $(findmnt -no SOURCE /) | head -n 1)
        [ -n "$BOOT_DISK" ] && sudo grub-install --target=i386-pc "/dev/$BOOT_DISK"
    fi

    # Config /etc/default/grub
    [ ! -f /etc/default/grub ] && sudo cp /usr/share/grub/default/grub /etc/default/grub 2>/dev/null || sudo touch /etc/default/grub
    
    # Enable os-prober and visuals
    sudo sed -i '/GRUB_DISABLE_OS_PROBER/d' /etc/default/grub
    echo 'GRUB_DISABLE_OS_PROBER=false' | sudo tee -a /etc/default/grub
    sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=8/' /etc/default/grub
    
    # Kernel parameters (Clean Boot)
    for param in "loglevel=3" "systemd.show_status=true"; do
        grep -q "$param" /etc/default/grub || sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"$param /" /etc/default/grub
    done
    sudo sed -i 's/quiet//g' /etc/default/grub

    # Theme
    THEME_NAME="grub-theme-vimix-very-dark-blue"
    THEME_PATH="/usr/share/grub/themes/$THEME_NAME/theme.txt"
    if [ ! -f "$THEME_PATH" ]; then
        if command -v yay &>/dev/null; then yay -S --needed --noconfirm "$THEME_NAME"; fi
    fi
    if [ -f "$THEME_PATH" ]; then
        sudo sed -i "/^GRUB_THEME=/d" /etc/default/grub
        echo "GRUB_THEME=\"$THEME_PATH\"" | sudo tee -a /etc/default/grub
    fi

    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# --- 4. Cleanup ---
while read -r mnt; do
    sudo umount "$mnt"
    rmdir "$mnt"
done < "$TEMP_MOUNTS"
rm -f "$TEMP_MOUNTS"

echo "--- Bootloader Configuration Complete! ---"
