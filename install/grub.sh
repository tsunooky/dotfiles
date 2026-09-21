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

# Whole disk holding /, for BIOS grub-install. findmnt may return
# "/dev/sda2[/@]" (btrfs subvolume) or a dm device (LVM/LUKS): strip the
# subvolume suffix, then walk the block-device tree up to the physical disk.
get_root_disk() {
    local src disk
    src=$(findmnt -no SOURCE / | sed 's/\[.*\]$//')
    [ -b "$src" ] || return 1
    disk=$(lsblk -slnpo NAME "$src" | tail -n 1)
    [ -b "$disk" ] && echo "$disk"
}

has_windows_files() {
    [ -f "$1/EFI/Microsoft/Boot/bootmgfw.efi" ] || [ -f "$1/bootmgr" ]
}

# --- 2. Deep Disk Scan (Windows) ---
echo "• Scanning for other operating systems..."
TEMP_MOUNTS=$(mktemp)

cleanup() {
    while read -r mnt; do
        sudo umount "$mnt" 2>/dev/null || true
        rmdir "$mnt" 2>/dev/null || true
    done < "$TEMP_MOUNTS"
    rm -f "$TEMP_MOUNTS"
}
trap cleanup EXIT

WINDOWS_FOUND=0
# Process substitution keeps the loop in the main shell so WINDOWS_FOUND is
# visible after the loop (a pipeline would run it in a subshell).
while read -r dev fstype mnt; do
    [ -z "$dev" ] && continue

    # Already mounted somewhere (e.g. shared ESP at /boot/efi): look there directly
    # instead of mounting the device a second time, which the kernel refuses.
    if [ -n "$mnt" ]; then
        if has_windows_files "$mnt"; then
            echo "  Found Windows on $dev ($mnt)"
            WINDOWS_FOUND=1
            break
        fi
        continue
    fi

    tmp=$(mktemp -d)
    if sudo mount -o ro "$dev" "$tmp" 2>/dev/null; then
        if has_windows_files "$tmp"; then
            echo "  Found Windows on $dev"
            # Keep it mounted until exit so os-prober can read it; cleanup unmounts.
            echo "$tmp" >> "$TEMP_MOUNTS"
            WINDOWS_FOUND=1
            break
        fi
        sudo umount "$tmp" 2>/dev/null || true
    fi
    rmdir "$tmp" 2>/dev/null || true
done < <(lsblk -lnpo NAME,FSTYPE,MOUNTPOINT | awk '$2 == "vfat" || $2 == "ntfs"')

# --- 3. Installation Strategy ---
if [ "$WINDOWS_FOUND" -eq 1 ]; then
    echo "✓ Windows detected. GRUB required for dual-boot."
elif [ -d "/boot/grub" ] || [ -f "/etc/default/grub" ]; then
    echo "• GRUB already active."
elif is_systemd_boot; then
    echo "• systemd-boot detected (no Windows). Skipping GRUB."
    exit 0
else
    echo "• No bootloader detected. Installing GRUB as default."
fi

# --- 4. GRUB Installation and Configuration ---
sudo pacman -S --needed --noconfirm grub efibootmgr os-prober ntfs-3g

# Binary installation
if is_uefi; then
    if ! EFI=$(get_efi_dir); then
        echo "✗ UEFI system but no EFI System Partition found mounted at /boot, /efi or /boot/efi."
        exit 1
    fi
    sudo grub-install --target=x86_64-efi --efi-directory="$EFI" --bootloader-id=GRUB --recheck
else
    if ! DISK=$(get_root_disk); then
        echo "✗ BIOS system but could not determine the disk holding / (source: $(findmnt -no SOURCE /))."
        exit 1
    fi
    sudo grub-install --target=i386-pc "$DISK"
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

# Theme Installation (cosmetic: never abort the install over it)
THEME="grub-theme-vimix-very-dark-blue"
if [ ! -f "/usr/share/grub/themes/$THEME/theme.txt" ] && command -v yay &>/dev/null; then
    yay -S --needed --noconfirm "$THEME" || echo "⚠ Failed to install $THEME, continuing without theme."
fi
if [ -f "/usr/share/grub/themes/$THEME/theme.txt" ]; then
    update_grub_config "GRUB_THEME" "\"/usr/share/grub/themes/$THEME/theme.txt\""
fi

sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "--- Bootloader Configuration Complete ---"
