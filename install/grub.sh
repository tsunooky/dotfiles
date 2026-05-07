#!/bin/bash

set -euo pipefail

# --- 1. Environment Detection Functions ---
is_uefi() { [ -d /sys/firmware/efi ]; }

is_systemd_boot() {
    command -v bootctl &>/dev/null && bootctl status 2>/dev/null | grep -q "bootloader-id: systemd-boot" && return 0
    for dir in /boot /efi /boot/efi; do [ -f "$dir/loader/loader.conf" ] && return 0; done
    return 1
}

get_efi_dir() {
    for dir in /boot /efi /boot/efi; do
        mountpoint -q "$dir" && [ -d "$dir/EFI" ] && echo "$dir" && return 0
    done
    local esp; esp=$(findmnt -no TARGET -t vfat | head -n 1)
    [ -n "$esp" ] && [ -d "$esp/EFI" ] && echo "$esp" && return 0
    return 1
}

# --- 2. Deep Disk Scan (Windows) ---
echo "• Scanning for other operating systems..."
TEMP_MOUNTS="/tmp/grub_temp_mounts"
rm -f "$TEMP_MOUNTS" && touch "$TEMP_MOUNTS"

WINDOWS_FOUND=0
lsblk -lno NAME,FSTYPE,MOUNTPOINT | grep -E "vfat|ntfs" | while read -r name fstype mnt; do
    dev="/dev/$name"
    # Check already mounted partitions
    [ -n "$mnt" ] && { [ "$mnt" = "/boot" ] || [ "$mnt" = "/efi" ] || [ "$mnt" = "/" ]; } && {
        ([ -f "$mnt/EFI/Microsoft/Boot/bootmgfw.efi" ] || [ -f "$mnt/bootmgr" ]) && exit 100
        continue
    }
    # Temporary mount for scanning
    tmp=$(mktemp -d)
    if sudo mount -o ro "$dev" "$tmp" 2>/dev/null; then
        if [ -f "$tmp/EFI/Microsoft/Boot/bootmgfw.efi" ] || [ -f "$tmp/bootmgr" ]; then
            echo "$tmp" >> "$TEMP_MOUNTS"
            exit 100
        fi
        sudo umount "$tmp" && rmdir "$tmp"
    else rmdir "$tmp"; fi
done || [ $? -eq 100 ] && WINDOWS_FOUND=1

# --- 3. Installation Strategy ---
if [ "$WINDOWS_FOUND" -eq 1 ]; then
    echo "✓ Windows detected. GRUB required for dual-boot."
    SHOULD_GRUB=1
elif [ -d "/boot/grub" ] || [ -f "/etc/default/grub" ]; then
    echo "• GRUB already active."
    SHOULD_GRUB=1
elif is_systemd_boot; then
    echo "• systemd-boot detected (no Windows). Skipping GRUB."
    while read -r mnt; do sudo umount "$mnt"; rmdir "$mnt"; done < "$TEMP_MOUNTS"
    rm -f "$TEMP_MOUNTS"
    exit 0
else
    echo "• No bootloader detected. Installing GRUB as default."
    SHOULD_GRUB=1
fi

# --- 4. GRUB Installation and Configuration ---
if [ "${SHOULD_GRUB:-0}" -eq 1 ]; then
    sudo pacman -S --needed --noconfirm grub efibootmgr os-prober ntfs-3g
    
    # Binary installation
    if is_uefi; then
        EFI=$(get_efi_dir || true)
        [ -n "$EFI" ] && sudo grub-install --target=x86_64-efi --efi-directory="$EFI" --bootloader-id=GRUB --recheck
    else
        DISK=$(lsblk -no PKNAME $(findmnt -no SOURCE /) | head -n 1)
        [ -n "$DISK" ] && sudo grub-install --target=i386-pc "/dev/$DISK"
    fi

    # Default configuration
    [ ! -f /etc/default/grub ] && { [ -f /usr/share/grub/default/grub ] && sudo cp /usr/share/grub/default/grub /etc/default/grub || sudo touch /etc/default/grub; }
    
    # Ensure settings are present and correct (idempotent)
    update_grub_config() {
        local var=$1
        local val=$2
        sudo sed -i "/^#\?${var}=/d" /etc/default/grub
        echo "${var}=${val}" | sudo tee -a /etc/default/grub
    }

    update_grub_config "GRUB_DISABLE_OS_PROBER" "false"
    update_grub_config "GRUB_DISABLE_SUBMENU" "y"
    update_grub_config "GRUB_TIMEOUT" "8"

    # Theme Installation
    THEME="grub-theme-vimix-very-dark-blue"
    if [ ! -f "/usr/share/grub/themes/$THEME/theme.txt" ] && command -v yay &>/dev/null; then
        yay -S --needed --noconfirm "$THEME"
    fi
    if [ -f "/usr/share/grub/themes/$THEME/theme.txt" ]; then
        sudo sed -i "/^GRUB_THEME=/d" /etc/default/grub
        echo "GRUB_THEME=\"/usr/share/grub/themes/$THEME/theme.txt\"" | sudo tee -a /etc/default/grub
    fi

    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# --- 5. Final Cleanup ---
while read -r mnt; do sudo umount "$mnt"; rmdir "$mnt"; done < "$TEMP_MOUNTS"
rm -f "$TEMP_MOUNTS"
echo "--- Bootloader Configuration Complete ---"
