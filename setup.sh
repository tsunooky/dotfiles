#!/bin/bash

# Robust Arch Linux Dotfiles Installation Script
# Exit on any error, log everything

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

LOGFILE="/var/log/dotfiles-install.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_PKGS="/tmp/dotfiles-installed-pkgs.txt"
SEP="════════════════════════════════════════════════════════════"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
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

log_title() {
    echo ""
    log "${BOLD}${BLUE}${SEP}${NC}"
    log "${BOLD}${BLUE} $1${NC}"
    log "${BOLD}${BLUE}${SEP}${NC}"
}

cleanup_on_error() {
    echo ""
    log "${RED}${SEP}${NC}"
    log "${RED}✗ INSTALLATION FAILED${NC}"
    log "${RED}  Error details stored in: ${LOGFILE}${NC}"
    log "${RED}${SEP}${NC}"
    
    if [ -f "${TEMP_PKGS}" ]; then
        echo "Packages installed before failure: $(cat ${TEMP_PKGS})" >> "${LOGFILE}"
    fi
    exit 1
}

trap cleanup_on_error ERR

# ============================================================================
# HARDWARE DETECTION
# ============================================================================

configure_hardware() {
    log_title "Hardware Detection"

    # --- Laptop/Battery ---
    local install_laptop="no"
    if ls /sys/class/power_supply/BAT* 1> /dev/null 2>&1; then
        install_laptop="yes"
        log "${GREEN}✓ Laptop detected (Battery found)${NC}"
    else
        log "${BLUE}ℹ Desktop detected (No battery)${NC}"
    fi

    export USER_PREF_INSTALL_LAPTOP="${install_laptop}"
    echo "INSTALL_LAPTOP=${install_laptop}" > /tmp/dotfiles-user-prefs.conf

    # --- DPI/Resolution ---
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

    # Apply DPI
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
        echo -e "${BLUE}  • ${pkg} already installed${NC}" >> "${LOGFILE}"
        return 0
    fi
    
    if [ "$manager" = "pacman" ]; then
        sudo pacman -S --noconfirm --needed "${pkg}" >> "${LOGFILE}" 2>&1
    else
        yay -S --noconfirm --answerdiff None --answerclean None "${pkg}" >> "${LOGFILE}" 2>&1
    fi
    
    echo "${pkg}" >> "${TEMP_PKGS}"
    log "${GREEN}  ✓ Installed: ${pkg}${NC}"
}

install_group() {
    log_title "$1"
    shift
    for pkg in "$@"; do
        [[ -z "${pkg}" || "${pkg}" =~ ^# ]] && continue
        install_package "${pkg}" "pacman"
    done
}

# ============================================================================
# MAIN STEPS
# ============================================================================

initial_setup() {
    log_title "System Update & Setup"
    
    sudo pacman -Syu --noconfirm >> "${LOGFILE}" 2>&1
    
    # Enable rfkill
    sudo systemctl enable rfkill-unblock@all 2>/dev/null || true
    
    # Essentials
    install_package "archlinux-keyring"
    install_package "sed"
    install_package "xorg-xrandr"

    # Configure Pacman (Candy) - Done after sed is installed
    sudo sed -i '/ILoveCandy/d' /etc/pacman.conf
    sudo sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf
}

install_packages_from_file() {
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
    log_title "Additional Components"
    
    # Yay
    if ! command -v yay &>/dev/null; then
        [ -f "${SCRIPT_DIR}/install/yay-install.sh" ] && bash "${SCRIPT_DIR}/install/yay-install.sh" >> "${LOGFILE}" 2>&1
        log "${GREEN}  ✓ yay installed${NC}"
    fi

    # i3lock-color
    if ! command -v i3lock &>/dev/null; then
        [ -f "${SCRIPT_DIR}/install/i3lock-color-install.sh" ] && bash "${SCRIPT_DIR}/install/i3lock-color-install.sh" >> "${LOGFILE}" 2>&1
        log "${GREEN}  ✓ i3lock-color installed${NC}"
    fi

    # Config Scripts
    local scripts=("firefox.sh" "vim-install.sh" "zsh-install.sh")
    for s in "${scripts[@]}"; do
        if [ -f "${SCRIPT_DIR}/install/$s" ]; then
            bash "${SCRIPT_DIR}/install/$s" >> "${LOGFILE}" 2>&1
            log "${GREEN}  ✓ Configured $(echo $s | cut -d'-' -f1 | cut -d'.' -f1)${NC}"
        fi
    done

    # Laptop
    source /tmp/dotfiles-user-prefs.conf
    if [[ "${INSTALL_LAPTOP}" == "yes" ]] && [ -f "${SCRIPT_DIR}/install/laptop.sh" ]; then
        bash "${SCRIPT_DIR}/install/laptop.sh" >> "${LOGFILE}" 2>&1
        log "${GREEN}  ✓ Laptop optimizations applied${NC}"
    fi
    
    # Matugen
    command -v yay &>/dev/null && install_package "matugen-bin" "yay"
}

finalize() {
    log_title "Finalizing"
    
    # Configs
    cp -a "${SCRIPT_DIR}/config/." ~/
    
    # Services
    sudo systemctl enable NetworkManager ly@tty2 2>/dev/null || true
    systemctl --user enable pipewire-pulse wireplumber 2>/dev/null || true
    
    # GTK & Fonts
    export GTK_THEME="Adwaita:dark"
    fc-cache -f >/dev/null 2>&1
    
    # Wallpaper scripts
    mkdir -p ~/.config/scripts
    echo -e "#!/bin/sh\n~/.config/scripts/change_wallpapers.sh ~/.wallpapers/default.jpg" > ~/.bg
    chmod +x ~/.bg
    
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
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    # Check root
    if [ "$EUID" -eq 0 ]; then
        echo -e "${RED}Error: Do not run as root.${NC}"
        exit 1
    fi

    # Init Log
    sudo touch "${LOGFILE}" && sudo chmod 666 "${LOGFILE}"
    > "${TEMP_PKGS}"
    
    clear
    echo -e "${BOLD}${BLUE}${SEP}${NC}"
    echo -e "${BOLD}${BLUE}   Arch Linux Dotfiles Installer${NC}"
    echo -e "${BOLD}${BLUE}${SEP}${NC}"
    echo -e "Logs: ${LOGFILE}"
    
    configure_hardware
    initial_setup
    install_packages_from_file
    run_scripts
    finalize
    
    rm -f "${TEMP_PKGS}"
    
    echo ""
    log "${GREEN}${SEP}${NC}"
    log "${GREEN}✓ INSTALLATION COMPLETED SUCCESSFULLY${NC}"
    log "${GREEN}  Please reboot your system.${NC}"
    log "${GREEN}  Full logs available at: ${LOGFILE}${NC}"
    log "${GREEN}${SEP}${NC}"
    echo ""
}

main
