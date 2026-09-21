#!/bin/bash

# ==============================================================================
# NVIDIA Setup Script (Arch Linux)
#
# Picks the driver branch from the GPU codename, following the Arch wiki table
# (https://wiki.archlinux.org/title/NVIDIA#Installation) and the 2025-12-20
# announcement that dropped the proprietary "nvidia"/"nvidia-dkms" packages:
#
#   Turing and newer (TU/GA/AD/GB)   -> nvidia-open (repo; -lts / -dkms per kernel)
#   Maxwell, Pascal, Volta (GM/GP/GV) -> nvidia-580xx-dkms (AUR, last supporting branch)
#   Kepler (GK)                       -> nvidia-470xx-dkms (AUR)
#   Fermi and older                   -> not packaged anymore, nouveau is used
#
# DRM modeset is set through /etc/modprobe.d so it applies whatever the boot
# loader (GRUB, systemd-boot, UKI). The initramfs is only rebuilt when this
# script actually changed something and the package hooks did not already do it.
# ==============================================================================

set -euo pipefail

YAY_OPTS=(--needed --noconfirm --answerdiff None --answerclean None)

# --- 1. GPU Detection ---
GPU_INFO=$(lspci -d 10de::03xx || true)
if [ -z "$GPU_INFO" ]; then
    echo "No NVIDIA GPU detected. Skipping NVIDIA-specific setup."
    exit 0
fi
echo "Detected NVIDIA GPU: $GPU_INFO"

CODENAME=$(grep -oE '\b(GB|AD|GA|TU|GV|GP|GM|GK|GF|GT|G)[0-9]{2,3}' <<< "$GPU_INFO" | head -n 1 || true)
case "$CODENAME" in
    GB*|AD*|GA*|TU*) BRANCH="open" ;;
    GV*|GP*|GM*)     BRANCH="580xx" ;;
    GK*)             BRANCH="470xx" ;;
    GF*|GT*|G*)
        echo "Fermi or older GPU ($CODENAME): no longer packaged on Arch, keeping the nouveau driver."
        exit 0 ;;
    *)
        # Unknown codename: most likely hardware newer than the pci.ids database.
        echo "Unknown GPU codename, assuming a recent GPU (open kernel modules)."
        BRANCH="open" ;;
esac
echo "Driver branch: $BRANCH (codename: ${CODENAME:-unknown})"

# --- 2. Package selection ---
mapfile -t KERNELS < <(pacman -Qq | grep -E '^linux(-lts|-zen|-hardened|-rt|-rt-lts)?$')
[ "${#KERNELS[@]}" -eq 0 ] && KERNELS=("linux")

HEADERS=()
for k in "${KERNELS[@]}"; do HEADERS+=("${k}-headers"); done

REPO_PKGS=()
AUR_PKGS=()
if [ "$BRANCH" = "open" ]; then
    # Prebuilt modules exist for linux and linux-lts; anything else needs dkms.
    for k in "${KERNELS[@]}"; do
        case "$k" in
            linux)     REPO_PKGS+=("nvidia-open") ;;
            linux-lts) REPO_PKGS+=("nvidia-open-lts") ;;
            *)         REPO_PKGS+=("nvidia-open-dkms") ;;
        esac
    done
    REPO_PKGS+=("nvidia-utils" "lib32-nvidia-utils" "nvidia-settings")
    BRANCH_RE='^(lib32-)?(opencl-)?nvidia(-open(-lts|-dkms)?|-utils|-settings)?$'
else
    AUR_PKGS=("nvidia-${BRANCH}-utils" "nvidia-${BRANCH}-dkms" "lib32-nvidia-${BRANCH}-utils" "nvidia-${BRANCH}-settings")
    BRANCH_RE="^(lib32-)?(opencl-)?nvidia-${BRANCH}"
fi

# --- 3. Enable Multilib (required for lib32 packages) ---
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo "Enabling multilib repository..."
    sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf
    sudo pacman -Syu --noconfirm
fi

# --- 4. Kernel configuration (done before installing so the package hooks
#        build the initramfs with the final configuration) ---
CONFIG_CHANGED=0

# DRM kernel mode setting. Default since driver 560 and patched in by the AUR
# legacy packages, but harmless to force: this is what the old GRUB_CMDLINE
# tweak tried to do, and it also works with systemd-boot and UKIs.
MODPROBE_CONF="/etc/modprobe.d/nvidia.conf"
if [ ! -f "$MODPROBE_CONF" ] || ! grep -q "modeset=1" "$MODPROBE_CONF"; then
    echo "Enabling DRM kernel mode setting in $MODPROBE_CONF..."
    echo "options nvidia_drm modeset=1" | sudo tee "$MODPROBE_CONF" > /dev/null
    CONFIG_CHANGED=1
fi

# Early KMS: load the driver from the initramfs so it is up before the display
# manager. Note: this breaks hibernation (video memory preservation).
if [ -f /etc/mkinitcpio.conf ] && ! grep -q "^MODULES=(.*nvidia_drm" /etc/mkinitcpio.conf; then
    echo "Configuring Early KMS in /etc/mkinitcpio.conf..."
    sudo sed -i -E 's/^MODULES=\((.*)\)/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm \1)/; /^MODULES=/ s/ +/ /g; /^MODULES=/ s/ \)/)/' /etc/mkinitcpio.conf
    CONFIG_CHANGED=1
fi

# --- 5. Remove packages from another branch ---
# pacman/yay cannot resolve the resulting conflicts non-interactively, so drop
# them explicitly (the loaded module keeps working until reboot).
mapfile -t INSTALLED < <(pacman -Qq | grep -E '^(lib32-)?(opencl-)?nvidia' | grep -vE '^linux-firmware-nvidia$' || true)
OTHER_BRANCH=()
for p in "${INSTALLED[@]}"; do
    [[ "$p" =~ $BRANCH_RE ]] || OTHER_BRANCH+=("$p")
done
if [ "${#OTHER_BRANCH[@]}" -gt 0 ]; then
    echo "Removing driver packages from another branch: ${OTHER_BRANCH[*]}"
    # -Rdd if something else depends on them (steam -> vulkan-driver, cuda...):
    # the new branch provides the same virtual packages right after.
    sudo pacman -Rn --noconfirm "${OTHER_BRANCH[@]}" \
        || sudo pacman -Rdd --noconfirm "${OTHER_BRANCH[@]}"
fi

# --- 6. Install ---
BEFORE=$(pacman -Q | grep -E 'nvidia|^dkms ' || true)

echo "Installing kernel headers and build tools (${HEADERS[*]})..."
sudo pacman -S --needed --noconfirm base-devel "${HEADERS[@]}"

if [ "${#REPO_PKGS[@]}" -gt 0 ]; then
    echo "Installing ${REPO_PKGS[*]}..."
    sudo pacman -S --needed --noconfirm "${REPO_PKGS[@]}"
fi
if [ "${#AUR_PKGS[@]}" -gt 0 ]; then
    if ! command -v yay &>/dev/null; then
        echo "Error: yay is required to install ${AUR_PKGS[*]} from the AUR."
        exit 1
    fi
    echo "Installing ${AUR_PKGS[*]} from the AUR (DKMS build, this takes a few minutes per kernel)..."
    yay -S "${YAY_OPTS[@]}" "${AUR_PKGS[@]}"
fi

# --- 7. Rebuild initramfs only if needed ---
# When a driver package was (re)installed, the dkms/mkinitcpio pacman hooks have
# already rebuilt every preset with the configuration written in step 4.
AFTER=$(pacman -Q | grep -E 'nvidia|^dkms ' || true)
if [ "$CONFIG_CHANGED" -eq 1 ] && [ "$BEFORE" = "$AFTER" ]; then
    echo "Rebuilding initramfs..."
    sudo mkinitcpio -P
fi

echo "--- NVIDIA Setup Complete (reboot required) ---"
