#!/bin/bash

clear
set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

LOGFILE="/var/log/dotfiles-install.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_PKGS="/tmp/dotfiles-installed-pkgs.txt"
INSTALL_LAPTOP="no"   # set by configure_hardware
DETECTED_DPI="96"     # set by configure_hardware
SEP_MAIN="════════════════════════════════════════════════════════════"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================================
# LOGGING & ERROR HANDLING
# ============================================================================

log() {
    local msg="$1"
    # To stdout: clean for the user (keep colors)
    echo -e "$msg"
    # To logfile: add timestamp and strip colors for readability
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$timestamp] $msg" | sed 's/\x1b\[[0-9;]*m//g' >> "${LOGFILE}" 2>/dev/null || true
}

log_main_title() {
    echo ""
    log "${BOLD}${BLUE}${SEP_MAIN}${NC}"
    log "${BOLD}${BLUE} $1${NC}"
    log "${BOLD}${BLUE}${SEP_MAIN}${NC}"
}

log_group_title() {
    log "${BOLD}${BLUE}──── $1 ────${NC}"
}

cleanup_on_error() {
    local exit_code=$?
    local line_number=$1
    local command=$2
    
    echo ""
    log "${RED}${SEP_MAIN}${NC}"
    log "${RED}✗ INSTALLATION FAILED${NC}"
    log "${RED}  Error in line ${line_number}: '${command}' (Exit code: ${exit_code})${NC}"
    log "${RED}  Full logs available at: ${LOGFILE}${NC}"
    log "${RED}${SEP_MAIN}${NC}"

    if [ -f "${TEMP_PKGS}" ]; then
        local pkgs
        pkgs=$(cat "${TEMP_PKGS}")
        if [ -n "$pkgs" ]; then
            log "${YELLOW}  Packages installed in this session: ${pkgs}${NC}"
        fi
    fi
    exit "${exit_code}"
}

trap 'cleanup_on_error $LINENO "$BASH_COMMAND"' ERR

# Ask for the password once, then refresh the sudo ticket in the background so
# it never expires during long steps (DKMS builds, AUR compilations...).
# Note: makepkg -s/-i deliberately runs "sudo -k" and always re-prompts, so no
# install script may use them (yay-install.sh installs with pacman -U instead).
SUDO_KEEPALIVE_PID=""
start_sudo_keepalive() {
    sudo -v
    ( while true; do sleep 60; sudo -n true; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
    SUDO_KEEPALIVE_PID=$!
}
stop_sudo_keepalive() {
    [ -n "${SUDO_KEEPALIVE_PID}" ] && kill "${SUDO_KEEPALIVE_PID}" 2>/dev/null || true
}
trap stop_sudo_keepalive EXIT

# ============================================================================
# VISUALS
# ============================================================================

show_banner() {
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC}  ${BOLD}${CYAN}      /\ ${NC}                                               ${BOLD}${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}║${NC}  ${BOLD}${CYAN}     /  \ ${NC}      ${BOLD}ARCH LINUX${NC}                              ${BOLD}${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}║${NC}  ${BOLD}${CYAN}    /    \ ${NC}     ${BOLD}DOTFILES INSTALLER${NC}                      ${BOLD}${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}║${NC}  ${BOLD}${CYAN}   /  /\  \ ${NC}    Setup & Configuration                   ${BOLD}${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}║${NC}  ${BOLD}${CYAN}  /  /  \  \ ${NC}                                           ${BOLD}${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}║${NC}  ${BOLD}${CYAN} /  /    \  \ ${NC}                                          ${BOLD}${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ============================================================================
# HARDWARE DETECTION
# ============================================================================

configure_hardware() {
    log_main_title "Hardware Detection"

    local install_laptop="no"
    if ls /sys/class/power_supply/BAT* 1> /dev/null 2>&1; then
        install_laptop="yes"
        log "${GREEN}✓ Laptop detected (Battery found)${NC}"
    else
        log "${CYAN}• Desktop detected (No battery)${NC}"
    fi

    INSTALL_LAPTOP="${install_laptop}"

    local detected_dpi="96"
    local current_res=""

    # Inside X (update run from i3): ask xrandr for the active mode
    if [ -n "${DISPLAY:-}" ] && command -v xrandr >/dev/null 2>&1; then
        current_res=$(xrandr 2>/dev/null | grep '\*' | awk '{print $1}' | head -n 1)
    fi

    # Fresh install runs from a TTY with no X server: take the preferred mode
    # (first line of "modes") of the first connected output from the DRM sysfs.
    if [ -z "$current_res" ]; then
        local status
        for status in /sys/class/drm/card*-*/status; do
            [ -f "$status" ] && [ "$(cat "$status")" = "connected" ] || continue
            current_res=$(head -n 1 "$(dirname "$status")/modes" 2>/dev/null)
            [ -n "$current_res" ] && break
        done
    fi

    if [ -n "$current_res" ]; then
        local width=$(echo "$current_res" | cut -d'x' -f1)

        if [ "$width" -ge 3000 ]; then detected_dpi="192"; # 4K or high-res
        elif [ "$width" -ge 2500 ]; then detected_dpi="132"; # QHD
        elif [ "$width" -ge 2100 ]; then detected_dpi="120"; # 2K
        else detected_dpi="96"; fi # FHD (1920) or lower

        log "${GREEN}✓ Resolution: ${current_res} -> DPI set to ${detected_dpi}${NC}"
    else
        log "${YELLOW}⚠ No connected display found, defaulting to 96 DPI${NC}"
    fi

    DETECTED_DPI="${detected_dpi}"
}

# ============================================================================
# PACKAGE MANAGEMENT
# ============================================================================

install_package() {
    local pkg="$1"
    local manager="${2:-pacman}"

    if pacman -Qi "$pkg" &>/dev/null; then
        log "${CYAN}• ${pkg} (already installed)${NC}"
        return 0
    fi

    if [ "$manager" = "pacman" ]; then
        sudo pacman -S --noconfirm --needed "${pkg}" >> "${LOGFILE}" 2>&1
    else
        yay -S --noconfirm --answerdiff None --answerclean None "${pkg}" >> "${LOGFILE}" 2>&1
    fi

    echo "${pkg}" >> "${TEMP_PKGS}"
    log "${GREEN}✓ Installed: ${pkg}${NC}"
}

# Installs a whole group in a single pacman transaction: every transaction
# re-runs the pacman hooks (fc-cache, icon caches, mkinitcpio...), so one
# per group instead of one per package saves minutes on a fresh install.
install_group() {
    log_group_title "$1"
    shift
    local pkg missing=()
    for pkg in "$@"; do
        [[ -z "${pkg}" || "${pkg}" =~ ^# ]] && continue
        if pacman -Qi "${pkg}" &>/dev/null; then
            log "${CYAN}• ${pkg} (already installed)${NC}"
        else
            missing+=("${pkg}")
        fi
    done

    if [ "${#missing[@]}" -gt 0 ]; then
        log "${CYAN}• Installing ${#missing[@]} package(s): ${missing[*]}${NC}"
        sudo pacman -S --noconfirm --needed "${missing[@]}" >> "${LOGFILE}" 2>&1
        printf '%s\n' "${missing[@]}" >> "${TEMP_PKGS}"
        for pkg in "${missing[@]}"; do
            log "${GREEN}✓ Installed: ${pkg}${NC}"
        done
    fi
    echo ""
}

# ============================================================================
# MAIN STEPS
# ============================================================================

initial_setup() {
    log_main_title "System Update & Essential Setup"
    log "${CYAN}• Updating system...${NC}"
    if sudo pacman -Syu --noconfirm 2>&1 | tee -a "${LOGFILE}"; then
        log "${GREEN}✓ System updated successfully${NC}"
    else
        log "${RED}✗ Failed to update system. Check ${LOGFILE}${NC}"
        return 1
    fi

    log "${CYAN}• Enabling rfkill-unblock service...${NC}"
    if sudo systemctl enable rfkill-unblock@all 2>/dev/null; then
        log "${GREEN}✓ rfkill-unblock@all enabled${NC}"
    else
        log "${YELLOW}⚠ Failed to enable rfkill-unblock@all (service may not exist)${NC}"
    fi

    log "${CYAN}• Installing essential tools (archlinux-keyring, sed)...${NC}"
    install_package "archlinux-keyring"
    install_package "sed"

    log "${CYAN}• Configuring Pacman (Candy & Parallel Downloads)...${NC}"
    sudo sed -i '/ILoveCandy/d' /etc/pacman.conf
    sudo sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf
    sudo sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

    # makepkg defaults to a single job: AUR builds (i3lock-color...) use every core
    log "${CYAN}• Configuring makepkg (parallel builds)...${NC}"
    sudo mkdir -p /etc/makepkg.conf.d
    echo 'MAKEFLAGS="-j$(nproc)"' | sudo tee /etc/makepkg.conf.d/parallel.conf > /dev/null
}

install_packages_from_file() {
    log_main_title "Installing Core Packages"
    local pkgs_file="${SCRIPT_DIR}/install/pkgs.txt"
    [ ! -f "${pkgs_file}" ] && return 1

    # A "# Group Name" line starts a group; groups are installed in file order.
    local current_group="" grp
    local -A groups
    local -a order=()

    while IFS= read -r line || [ -n "$line" ]; do
        [[ -z "${line}" ]] && continue
        if [[ "${line}" =~ ^#[[:space:]](.+)$ ]]; then
            current_group="${BASH_REMATCH[1]}"
            groups["${current_group}"]=""
            order+=("${current_group}")
            continue
        fi
        [[ "${line}" =~ ^# ]] && continue
        [ -n "${current_group}" ] && groups["${current_group}"]+="${line} "
    done < "${pkgs_file}"

    for grp in "${order[@]}"; do
        [ -n "${groups[$grp]:-}" ] && install_group "$grp" ${groups[$grp]}
    done
}

# run_install_script <script> <label> [long]
# Runs install/<script> with its output in the log file. "long" adds a hint so
# a multi-minute step (DKMS build, AUR compilation) does not look frozen.
run_install_script() {
    local script="$1" label="$2" long="${3:-}"
    if [ ! -f "${SCRIPT_DIR}/install/${script}" ]; then
        log "${YELLOW}⚠ install/${script} not found, skipping ${label}${NC}"
        return 0
    fi
    if [ -n "$long" ]; then
        log "${CYAN}• ${label}... (can take several minutes: tail -f ${LOGFILE})${NC}"
    else
        log "${CYAN}• ${label}...${NC}"
    fi
    bash "${SCRIPT_DIR}/install/${script}" >> "${LOGFILE}" 2>&1
    log "${GREEN}✓ ${label} done${NC}"
}

run_scripts() {
    log_main_title "Additional Components"

    if command -v yay &>/dev/null; then
        log "${CYAN}• yay already installed, skipping.${NC}"
    else
        run_install_script "yay-install.sh" "Installing yay (AUR helper)"
    fi

    run_install_script "i3lock-color-install.sh" "Checking/Installing i3lock-color" long
    run_install_script "ly.sh" "Configuring ly"
    run_install_script "grub.sh" "Configuring grub"
    run_install_script "gpu.sh" "Configuring GPU drivers" long
    run_install_script "firefox.sh" "Configuring firefox"
    run_install_script "zsh-install.sh" "Configuring zsh"
    run_install_script "wallpapers.sh" "Downloading wallpapers"

    if [[ "${INSTALL_LAPTOP}" == "yes" ]]; then
        run_install_script "laptop.sh" "Applying laptop optimizations (TLP, acpid)"
    fi

    # Matugen
    if command -v yay &>/dev/null; then
        log "${CYAN}• Checking/Updating matugen-bin...${NC}"
        yay -S --noconfirm --needed --answerdiff None --answerclean None matugen-bin >> "${LOGFILE}" 2>&1
        log "${GREEN}✓ matugen-bin checked${NC}"
    else
        log "${YELLOW}⚠ yay not found, skipping matugen-bin.${NC}"
    fi
}

finalize() {
    log_main_title "Finalizing Setup"

    local is_update=false
    if [ -f "$HOME/.config/scripts/matugen-reload.sh" ]; then
        is_update=true
    fi

    log "${CYAN}• Cleaning old Neovim configuration...${NC}"
    rm -rf ~/.config/nvim
    
    log "${CYAN}• Copying configuration files...${NC}"
    cp -a "${SCRIPT_DIR}/config/." ~/
    log "${GREEN}✓ Configuration files copied${NC}"

    log "${CYAN}• Applying hardware-specific configurations...${NC}"
    # Apply DPI to polybar
    if [ -f ~/.config/polybar/config.ini ]; then
        sed -i "s/{{DPI}}/${DETECTED_DPI:-96}/g" ~/.config/polybar/config.ini
    fi

    # Create .Xresources
    echo "Xft.dpi: ${DETECTED_DPI:-96}
Xft.autohint: 0
Xft.lcdfilter: lcddefault
Xft.hintstyle: hintfull
Xft.hinting: 1
Xft.antialias: 1
Xft.rgba: rgb" > ~/.Xresources

    # Only Downloads: no xdg-user-dirs, which would also create Music, Documents...
    mkdir -p ~/Downloads

    log "${CYAN}• Enabling system services...${NC}"
    sudo systemctl enable NetworkManager 2>/dev/null || true
    sudo systemctl enable --now bluetooth.service 2>/dev/null || true
    # Already enabled by the package presets on Arch; harmless, kept for other setups
    systemctl --user enable pipewire-pulse wireplumber 2>/dev/null || true
    log "${GREEN}✓ Services enabled (Network, Bluetooth, Audio)${NC}"

    log "${CYAN}• Updating font cache...${NC}"
    fc-cache -f >/dev/null 2>&1
    log "${GREEN}✓ Font cache updated${NC}"

    if [ "$is_update" = "false" ]; then
        log "${CYAN}• Creating first-run wallpaper setup...${NC}"
        cat > ~/.config/i3/autostart_once.sh << 'EOF'
#!/bin/bash
[ -f ~/.wallpapers/default.jpg ] && ~/.config/scripts/change_wallpaper.sh ~/.wallpapers/default.jpg
sed -i '/exec.*autostart_once\.sh/d' ~/.config/i3/config
rm -f ~/.config/i3/autostart_once.sh
i3-msg restart
pywalfox update
EOF
        chmod +x ~/.config/i3/autostart_once.sh
        echo "exec_always --no-startup-id ~/.config/i3/autostart_once.sh" >> ~/.config/i3/config
        log "${GREEN}✓ First-run setup configured${NC}"
    else
        log "${CYAN}• Update detected, skipping first-run wallpaper setup.${NC}"
    fi

    # Needs ~/.vimrc, so it must run after the configuration files are copied
    run_install_script "vim-install.sh" "Installing Vim plugins"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    if [ "$EUID" -eq 0 ]; then
        echo -e "${RED}Error: Do not run this script as root. Use a regular user with sudo privileges.${NC}"
        exit 1
    fi

    show_banner

    start_sudo_keepalive
    # Owned by the user so that log() and the sub-scripts can append to it directly
    sudo touch "${LOGFILE}" && sudo chown "$(id -un)" "${LOGFILE}" && sudo chmod 644 "${LOGFILE}"
    > "${TEMP_PKGS}"

    initial_setup
    install_packages_from_file
    configure_hardware
    run_scripts
    finalize

    rm -f "${TEMP_PKGS}"

    echo ""
    log "${GREEN}${SEP_MAIN}${NC}"
    log "${GREEN}✓ INSTALLATION COMPLETED SUCCESSFULLY${NC}"
    log "${GREEN}  Please reboot your system.${NC}"
    log "${GREEN}  Full logs available at: ${LOGFILE}${NC}"
    log "${GREEN}${SEP_MAIN}${NC}"
    echo ""
}

main
