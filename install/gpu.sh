#!/bin/bash

# ==============================================================================
# GPU Setup Script (Arch Linux)
#
# Detects every display controller (lspci class 03xx) and installs the user
# space drivers for each vendor found, so hybrid laptops get both blocks:
#
#   AMD    (1002) -> mesa (includes the VA-API driver) + vulkan-radeon (+ lib32)
#   Intel  (8086) -> mesa + vulkan-intel + intel-media-driver (+ lib32)
#   NVIDIA (10de) -> branch picked from the GPU codename, following the Arch
#                    wiki table (https://wiki.archlinux.org/title/NVIDIA) and
#                    the 2025-12-20 announcement that dropped "nvidia-dkms":
#                      Turing and newer (TU/GA/AD/GB)    -> nvidia-open (repo)
#                      Maxwell, Pascal, Volta (GM/GP/GV) -> nvidia-580xx-dkms (AUR)
#                      Kepler (GK)                       -> nvidia-470xx-dkms (AUR)
#                      Fermi and older                   -> nouveau (not packaged)
#
# AMD and Intel need nothing else: the kernel ships amdgpu/i915 and Xorg uses
# the modesetting driver. Multilib is enabled for every vendor (Steam, Wine).
# ==============================================================================

set -euo pipefail

YAY_OPTS=(--needed --noconfirm --answerdiff None --answerclean None)

# --- 1. Detection ---
GPUS=$(lspci -d ::03xx || true)
if [ -z "$GPUS" ]; then
    echo "No display controller found. Skipping GPU setup."
    exit 0
fi
echo "Display controllers:"
echo "$GPUS" | sed 's/^/  /'

# No "| grep -q": with pipefail, grep closing the pipe early would make lspci
# exit with SIGPIPE and the test fail.
has_vendor() { [ -n "$(lspci -d "$1::03xx" 2>/dev/null)" ]; }

# --- 2. Multilib (lib32 packages for 32-bit apps: Steam, Wine...) ---
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo "Enabling multilib repository..."
    sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf
    sudo pacman -Syu --noconfirm
fi

# --- 3. AMD / Intel (repo packages, no compilation) ---
MESA_PKGS=()
if has_vendor 1002; then
    echo "AMD GPU detected."
    MESA_PKGS+=(mesa vulkan-radeon lib32-mesa lib32-vulkan-radeon)
fi
if has_vendor 8086; then
    echo "Intel GPU detected."
    # intel-media-driver: Broadwell+ ; libva-intel-driver: older generations
    MESA_PKGS+=(mesa vulkan-intel intel-media-driver libva-intel-driver lib32-mesa lib32-vulkan-intel)
fi
if [ "${#MESA_PKGS[@]}" -gt 0 ]; then
    mapfile -t MESA_PKGS < <(printf '%s\n' "${MESA_PKGS[@]}" | sort -u)
    echo "Installing ${MESA_PKGS[*]}..."
    sudo pacman -S --needed --noconfirm "${MESA_PKGS[@]}"
    # mesa is otherwise only pulled in as a dependency of libglvnd
    sudo pacman -D --asexplicit mesa > /dev/null
fi

# --- 4. NVIDIA ---
setup_nvidia() {
    local gpu_info codename branch
    gpu_info=$(lspci -d 10de::03xx)
    echo "NVIDIA GPU detected: $gpu_info"

    codename=$(grep -oE '\b(GB|AD|GA|TU|GV|GP|GM|GK|GF|GT|G)[0-9]{2,3}' <<< "$gpu_info" | head -n 1 || true)
    case "$codename" in
        GB*|AD*|GA*|TU*) branch="open" ;;
        GV*|GP*|GM*)     branch="580xx" ;;
        GK*)             branch="470xx" ;;
        GF*|GT*|G*)
            echo "Fermi or older GPU ($codename): no longer packaged on Arch, keeping the nouveau driver."
            return 0 ;;
        *)
            # Unknown codename: most likely hardware newer than the pci.ids database.
            echo "Unknown GPU codename, assuming a recent GPU (open kernel modules)."
            branch="open" ;;
    esac
    echo "Driver branch: $branch (codename: ${codename:-unknown})"

    # Package selection
    local -a kernels headers repo_pkgs aur_pkgs
    mapfile -t kernels < <(pacman -Qq | grep -E '^linux(-lts|-zen|-hardened|-rt|-rt-lts)?$')
    [ "${#kernels[@]}" -eq 0 ] && kernels=("linux")

    headers=()
    local k
    for k in "${kernels[@]}"; do headers+=("${k}-headers"); done

    local branch_re
    repo_pkgs=()
    aur_pkgs=()
    if [ "$branch" = "open" ]; then
        # Prebuilt modules exist for linux and linux-lts; anything else needs dkms.
        for k in "${kernels[@]}"; do
            case "$k" in
                linux)     repo_pkgs+=("nvidia-open") ;;
                linux-lts) repo_pkgs+=("nvidia-open-lts") ;;
                *)         repo_pkgs+=("nvidia-open-dkms") ;;
            esac
        done
        repo_pkgs+=("nvidia-utils" "lib32-nvidia-utils" "nvidia-settings")
        branch_re='^((lib32-)?(opencl-)?nvidia(-open(-lts|-dkms)?|-utils|-settings)?|libxnvctrl)$'
    else
        aur_pkgs=("nvidia-${branch}-utils" "nvidia-${branch}-dkms" "lib32-nvidia-${branch}-utils" "nvidia-${branch}-settings")
        branch_re="^((lib32-)?(opencl-)?nvidia-${branch}|libxnvctrl-${branch})"
    fi

    # Kernel configuration, done before installing so the package hooks build
    # the initramfs with the final configuration.
    local config_changed=0

    # DRM kernel mode setting. Default since driver 560 and patched in by the
    # AUR legacy packages, but harmless to force. Set through modprobe.d so it
    # applies whatever the boot loader (GRUB, systemd-boot, UKI).
    local modprobe_conf="/etc/modprobe.d/nvidia.conf"
    if [ ! -f "$modprobe_conf" ] || ! grep -q "modeset=1" "$modprobe_conf"; then
        echo "Enabling DRM kernel mode setting in $modprobe_conf..."
        echo "options nvidia_drm modeset=1" | sudo tee "$modprobe_conf" > /dev/null
        config_changed=1
    fi

    # Early KMS: load the driver from the initramfs so it is up before the
    # display manager. Note: this breaks hibernation (video memory preservation).
    if [ -f /etc/mkinitcpio.conf ] && ! grep -q "^MODULES=(.*nvidia_drm" /etc/mkinitcpio.conf; then
        echo "Configuring Early KMS in /etc/mkinitcpio.conf..."
        sudo sed -i -E 's/^MODULES=\((.*)\)/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm \1)/; /^MODULES=/ s/ +/ /g; /^MODULES=/ s/ \)/)/' /etc/mkinitcpio.conf
        config_changed=1
    fi

    # Remove packages from another branch: pacman/yay cannot resolve the
    # resulting conflicts non-interactively (the loaded module keeps working
    # until reboot). libxnvctrl is the nvidia-settings dependency: each branch
    # ships its own and they conflict, so it must go too.
    local -a installed other_branch
    mapfile -t installed < <(pacman -Qq | grep -E '^((lib32-)?(opencl-)?nvidia|libxnvctrl)' | grep -vE '^linux-firmware-nvidia$' || true)
    other_branch=()
    local p
    for p in "${installed[@]}"; do
        [[ "$p" =~ $branch_re ]] || other_branch+=("$p")
    done
    if [ "${#other_branch[@]}" -gt 0 ]; then
        echo "Removing driver packages from another branch: ${other_branch[*]}"
        # -Rdd if something else depends on them (steam -> vulkan-driver, cuda...):
        # the new branch provides the same virtual packages right after.
        sudo pacman -Rn --noconfirm "${other_branch[@]}" \
            || sudo pacman -Rdd --noconfirm "${other_branch[@]}"
    fi

    # Install
    local before after
    before=$(pacman -Q | grep -E 'nvidia|^dkms ' || true)

    echo "Installing kernel headers and build tools (${headers[*]})..."
    sudo pacman -S --needed --noconfirm base-devel "${headers[@]}"

    if [ "${#repo_pkgs[@]}" -gt 0 ]; then
        echo "Installing ${repo_pkgs[*]}..."
        sudo pacman -S --needed --noconfirm "${repo_pkgs[@]}"
    fi
    if [ "${#aur_pkgs[@]}" -gt 0 ]; then
        if ! command -v yay &>/dev/null; then
            echo "Error: yay is required to install ${aur_pkgs[*]} from the AUR."
            return 1
        fi
        echo "Installing ${aur_pkgs[*]} from the AUR (DKMS build, this takes a few minutes per kernel)..."
        yay -S "${YAY_OPTS[@]}" "${aur_pkgs[@]}"
    fi

    # Rebuild the initramfs only if needed: when a driver package was
    # (re)installed, the dkms/mkinitcpio pacman hooks already rebuilt every
    # preset with the configuration written above.
    after=$(pacman -Q | grep -E 'nvidia|^dkms ' || true)
    if [ "$config_changed" -eq 1 ] && [ "$before" = "$after" ]; then
        echo "Rebuilding initramfs..."
        sudo mkinitcpio -P
    fi
    echo "NVIDIA driver installed (reboot required)."
}

if has_vendor 10de; then
    setup_nvidia
fi

echo "--- GPU Setup Complete ---"
