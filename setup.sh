#!/bin/bash

clear
set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

LOGFILE="/var/log/dotfiles-install.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_PKGS="/tmp/dotfiles-installed-pkgs.txt"
SEP_MAIN="════════════════════════════════════════════════════════════"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================================
# LOGGING & ERROR HANDLING
# ============================================================================

log() {
    local msg="[$(date '+%H:%M:%S')] $1"
    echo -e "$msg" | sudo tee -a "${LOGFILE}" > /dev/null
    echo -e "$1"
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
    echo ""
    log "${RED}${SEP_MAIN}${NC}"
    log "${RED}✗ INSTALLATION FAILED${NC}"
    log "${RED}  Error details stored in: ${LOGFILE}${NC}"
    log "${RED}${SEP_MAIN}${NC}"

    if [ -f "${TEMP_PKGS}" ]; then
        echo "Packages installed before failure: $(cat ${TEMP_PKGS})" >> "${LOGFILE}"
    fi
    exit 1
}

trap cleanup_on_error ERR

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

    export USER_PREF_INSTALL_LAPTOP="${install_laptop}"
    echo "INSTALL_LAPTOP=${install_laptop}" > /tmp/dotfiles-user-prefs.conf

    local detected_dpi="96"

    if command -v xrandr >/dev/null 2>&1; then
        local current_res=$(xrandr 2>/dev/null | grep '*' | awk '{print $1}' | head -n 1)
        if [ -n "$current_res" ]; then
            local width=$(echo "$current_res" | cut -d'x' -f1)

            if [ "$width" -ge 3000 ]; then detected_dpi="192"; # 4K / Mac
            elif [ "$width" -ge 2100 ]; then detected_dpi="144"; # 2K
            else detected_dpi="96"; fi # FHD

            log "${GREEN}✓ Resolution: ${current_res} -> DPI set to ${detected_dpi}${NC}"
        else
            log "${YELLOW}⚠ No active resolution found, defaulting to 96 DPI${NC}"
        fi
    else
        log "${YELLOW}⚠ xrandr missing, defaulting to 96 DPI${NC}"
    fi

    if [ -f "${SCRIPT_DIR}/config/.config/polybar/config.ini" ]; then
        sed -i "s/{{DPI}}/${detected_dpi}/g" "${SCRIPT_DIR}/config/.config/polybar/config.ini"
    fi

    echo "Xft.dpi: ${detected_dpi}
Xft.autohint: 0
Xft.lcdfilter: lcddefault
Xft.hintstyle: hintfull
Xft.hinting: 1
Xft.antialias: 1
Xft.rgba: rgb" > "${SCRIPT_DIR}/config/.Xresources"
}

# ============================================================================
# PACKAGE MANAGEMENT
# ============================================================================

install_package() {
    local pkg="$1"
    local manager="${2:-pacman}"

    if pacman -Qi "$pkg" &>/dev/null || (command -v yay &>/dev/null && yay -Qi "$pkg" &>/dev/null); then
        log "${CYAN}• ${pkg} (already installed)${NC}"
        echo "• ${pkg} already installed" >> "${LOGFILE}"
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

install_group() {
    log_group_title "$1"
    shift
    for pkg in "$@"; do
        [[ -z "${pkg}" || "${pkg}" =~ ^# ]] && continue
        install_package "${pkg}" "pacman"
    done
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

    log "${CYAN}• Installing essential tools (archlinux-keyring, sed, xorg-xrandr)...${NC}"
    install_package "archlinux-keyring"
    install_package "sed"
    install_package "xorg-xrandr"

    log "${CYAN}• Configuring Pacman (Candy & Parallel Downloads)...${NC}"
    sudo sed -i '/ILoveCandy/d' /etc/pacman.conf
    sudo sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf
    sudo sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
}

install_packages_from_file() {
    log_main_title "Installing Core Packages"
    local pkgs_file="${SCRIPT_DIR}/install/pkgs.txt"
    [ ! -f "${pkgs_file}" ] && return 1

    local current_group=""
    local -A groups

    while IFS= read -r line || [ -n "$line" ]; do
        [[ -z "${line}" ]] && continue
        if [[ "${line}" =~ ^#[[:space:]](.+)$ ]]; then
            current_group="${BASH_REMATCH[1]}"
            groups["${current_group}"]=""
            continue
        fi
        [[ "${line}" =~ ^# ]] && continue
        [ -n "${current_group}" ] && groups["${current_group}"]+="${line} "
    done < "${pkgs_file}"

    local order=("Base Development Tools" "System Tools & Utilities" "Xorg Display Server" 
                 "Audio System (Pipewire)" "Network Management" "i3 Window Manager & Compositor" 
                 "Desktop Utilities" "Fonts & Themes" "Applications")

    for grp in "${order[@]}"; do
        [ -n "${groups[$grp]:-}" ] && install_group "$grp" ${groups[$grp]}
    done
}

run_scripts() {
    log_main_title "Additional Components"

    # Yay
    if ! command -v yay &>/dev/null; then
        log "${CYAN}• Installing yay (AUR helper)...${NC}"
        [ -f "${SCRIPT_DIR}/install/yay-install.sh" ] && bash "${SCRIPT_DIR}/install/yay-install.sh" >> "${LOGFILE}" 2>&1
        log "${GREEN}✓ yay installed${NC}"
    else
        log "${CYAN}• yay already installed, skipping.${NC}"
    fi

    # i3lock-color
    if ! command -v i3lock &>/dev/null; then
        log "${CYAN}• Building i3lock-color from source...${NC}"
        [ -f "${SCRIPT_DIR}/install/i3lock-color-install.sh" ] && bash "${SCRIPT_DIR}/install/i3lock-color-install.sh" >> "${LOGFILE}" 2>&1
        log "${GREEN}✓ i3lock-color installed${NC}"
    else
        log "${CYAN}• i3lock-color already installed, skipping rebuild.${NC}"
    fi

    # Config Scripts
    local scripts=("firefox.sh" "vim-install.sh" "zsh-install.sh")
    for s in "${scripts[@]}"; do
        if [ -f "${SCRIPT_DIR}/install/$s" ]; then
            log "${CYAN}• Configuring $(echo $s | cut -d'-' -f1 | cut -d'.' -f1)...${NC}"
            bash "${SCRIPT_DIR}/install/$s" >> "${LOGFILE}" 2>&1
            log "${GREEN}✓ $(echo $s | cut -d'-' -f1 | cut -d'.' -f1) configured${NC}"
        fi
    done

    # Laptop
    source /tmp/dotfiles-user-prefs.conf
    if [[ "${INSTALL_LAPTOP}" == "yes" ]] && [ -f "${SCRIPT_DIR}/install/laptop.sh" ]; then
        log "${CYAN}• Applying laptop optimizations (TLP, acpid)...${NC}"
        bash "${SCRIPT_DIR}/install/laptop.sh" >> "${LOGFILE}" 2>&1
        log "${GREEN}✓ Laptop optimizations applied${NC}"
    fi

    # Matugen
    if command -v yay &>/dev/null; then
        log "${CYAN}• Installing matugen-bin...${NC}"
        install_package "matugen-bin" "yay"
    else
        log "${YELLOW}⚠ yay not found, skipping matugen-bin installation.${NC}"
    fi
}

finalize() {
    log_main_title "Finalizing Setup"

    log "${CYAN}• Copying configuration files...${NC}"
    cp -a "${SCRIPT_DIR}/config/." ~/
    log "${GREEN}✓ Configuration files copied${NC}"

    log "${CYAN}• Enabling system services...${NC}"
    sudo systemctl enable NetworkManager 2>/dev/null || true
    sudo systemctl enable ly@tty2 2>/dev/null || true

    sudo systemctl enable --now bluetooth.service 2>/dev/null || true

    systemctl --user enable pipewire-pulse wireplumber 2>/dev/null || true
    log "${GREEN}✓ Services enabled (Network, Bluetooth, Audio, Login)${NC}"

    log "${CYAN}• Setting GTK theme and updating font cache...${NC}"
    export GTK_THEME="Adwaita:dark"
    fc-cache -f >/dev/null 2>&1
    log "${GREEN}✓ GTK theme set, font cache updated${NC}"

    log "${CYAN}• Creating background script...${NC}"
    mkdir -p ~/.config/scripts
    echo -e "#!/bin/sh\n~/.config/scripts/change_wallpapers.sh ~/.wallpapers/default.jpg" > ~/.bg
    chmod +x ~/.bg
    log "${GREEN}✓ Background script created${NC}"

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

    sudo touch "${LOGFILE}" && sudo chmod 666 "${LOGFILE}"
    > "${TEMP_PKGS}"

    configure_hardware
    initial_setup
    install_packages_from_file
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
