#!/bin/bash

set -euo pipefail

# --- 1. Environment Detection Functions ---
is_uefi() { [ -d /sys/firmware/efi ]; }

is_systemd_boot() {
    command -v bootctl &>/dev/null && bootctl status 2>/dev/null | grep -q "bootloader-id: systemd-boot" && return 0
    for dir in /boot /efi /boot/efi; do [ -f "$dir/loader/loader.conf" ] && return 0; done
    return 1
}

# The ESP is often mounted root-only (archinstall uses fmask=0177,dmask=0077):
# a plain [ -d ] run as the regular user cannot see inside it, hence sudo test.
get_efi_dir() {
    for dir in /boot /efi /boot/efi; do
        mountpoint -q "$dir" && sudo test -d "$dir/EFI" && echo "$dir" && return 0
    done
    local esp; esp=$(findmnt -no TARGET -t vfat | head -n 1)
    [ -n "$esp" ] && sudo test -d "$esp/EFI" && echo "$esp" && return 0
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
    sudo test -f "$1/EFI/Microsoft/Boot/bootmgfw.efi" || sudo test -f "$1/bootmgr"
}

# sbctl reports "installed" once its signing keys exist. Here-strings instead of
# "| grep -q": with pipefail, grep closing the pipe early can fail the test.
has_sbctl_keys() {
    command -v sbctl &>/dev/null || return 1
    grep -Eq '"installed": *true' <<< "$(sudo sbctl status --json 2>/dev/null || true)"
}

# True when a firmware boot entry (whatever its label) already starts
# \EFI\GRUB\grubx64.efi from the ESP mounted at $1.
has_grub_boot_entry() {
    local partuuid entries
    partuuid=$(lsblk -no PARTUUID "$(findmnt -no SOURCE "$1")" 2>/dev/null || true)
    [ -n "$partuuid" ] || return 1
    entries=$(sudo efibootmgr 2>/dev/null || true)
    grep -i "$partuuid" <<< "$entries" | grep -iF '\EFI\GRUB\grubx64.efi' > /dev/null
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
    GRUB_ARGS=(--target=x86_64-efi --efi-directory="$EFI" --bootloader-id=GRUB --recheck)

    # Leave the firmware boot entries and boot order alone when an entry already
    # starts this GRUB: re-running the dotfiles must not put GRUB back in front
    # of another OS chosen as the default (e.g. Windows first, Arch via F12).
    if has_grub_boot_entry "$EFI"; then
        GRUB_ARGS+=(--no-nvram)
    fi

    # Secure Boot with sbctl keys: when Secure Boot is on, GRUB runs in lockdown
    # mode and refuses to load modules from disk, so every module grub.cfg needs
    # (theme, os-prober chainloading, firmware setup entry, 25_bli) is embedded in the
    # image, shim_lock is disabled (no shim) and the image is signed below.
    # Without sbctl keys, this is the plain install as before.
    SBCTL=0
    if has_sbctl_keys; then
        SBCTL=1
        GRUB_ARGS+=(--disable-shim-lock --modules="tpm part_gpt part_msdos fat ext2 ntfs normal linux chain search search_fs_uuid search_fs_file search_label configfile echo test true loadenv gzio all_video video gfxterm gfxterm_background gfxmenu font png jpeg minicmd reboot halt efifwsetup bli")
        echo "• sbctl keys found: installing GRUB for Secure Boot."
    fi

    sudo grub-install "${GRUB_ARGS[@]}"

    # -s saves each file in the sbctl database, so its pacman hook re-signs
    # them on every kernel update. Signing an already signed file is a no-op.
    if [ "$SBCTL" -eq 1 ]; then
        sudo sbctl sign -s "$EFI/EFI/GRUB/grubx64.efi"
        for kernel in /boot/vmlinuz-*; do
            if [ -f "$kernel" ]; then sudo sbctl sign -s "$kernel"; fi
        done
    fi
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

# --- TEMP (desktop dual boot): remove once the setup is validated ---
# Hide the stale Windows ESP left on the Samsung 850 EVO data disk from the
# GRUB menu (os-prober skip list, nothing is written to that disk).
OLD_WIN_DISK=$(lsblk -dnpo NAME,MODEL | awk '/850 EVO/ {print $1; exit}' || true)
if [ -n "$OLD_WIN_DISK" ]; then
    OLD_ESP_UUID=$(lsblk -nro FSTYPE,UUID "$OLD_WIN_DISK" | awk '$1 == "vfat" {print $2; exit}' || true)
    if [ -n "$OLD_ESP_UUID" ]; then
        update_grub_config "GRUB_OS_PROBER_SKIP_LIST" "\"${OLD_ESP_UUID}@/efi/Microsoft/Boot/bootmgfw.efi\""
    fi
fi
# --- END TEMP ---

sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "--- Bootloader Configuration Complete ---"

# --- TEMP (desktop dual boot): diagnostics, remove once the setup is validated ---
# Also saved to ~/grub-diag.txt (cat it to see it again).
grub_diag() {
    echo "=================== grub.sh diag (temp v1) ==================="
    echo "--- sbctl verify"
    sudo sbctl verify 2>&1 || true
    echo "--- efibootmgr"
    sudo efibootmgr 2>&1 | cut -c1-110 || true
    echo "--- /etc/default/grub"
    grep -E '^GRUB_(DEFAULT|TIMEOUT|TOP_LEVEL|DISABLE_OS_PROBER|DISABLE_SUBMENU|OS_PROBER_SKIP_LIST|THEME)=' /etc/default/grub || true
    echo "--- grub.cfg entries"
    sudo grep -E '^(menuentry|submenu)' /boot/grub/grub.cfg | cut -c1-80 || true
    echo "--- grub.cfg insmod"
    { sudo grep -o 'insmod [a-z0-9_]*' /boot/grub/grub.cfg | awk '{print $2}' | sort -u | tr '\n' ' '; echo; } || true
    echo "==============================================================="
}
grub_diag 2>&1 | tee "$HOME/grub-diag.txt"
# --- END TEMP ---
