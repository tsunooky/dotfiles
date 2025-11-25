#!/bin/bash

# Robust Arch Linux Dotfiles Installation Script
# Exit on any error, log everything, install packages individually

set -euo pipefail

# Clear terminal for clean start
clear

# ============================================================================
# CONFIGURATION
# ============================================================================

LOGFILE="/var/log/dotfiles-install.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_INSTALLED_PKGS="/tmp/dotfiles-installed-pkgs.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "${message}" | sudo tee -a "${LOGFILE}" > /dev/null
    echo -e "$1"
}

log_success() {
    log "${GREEN}✓ $1${NC}"
}

log_error() {
    log "${RED}✗ ERROR: $1${NC}"
}

log_warning() {
    log "${YELLOW}⚠ WARNING: $1${NC}"
}

log_info() {
    log "${BLUE}$1${NC}"
}

# ============================================================================
# ERROR HANDLING
# ============================================================================

cleanup_on_error() {
    log_error "Installation failed. Running cleanup..."
    
    if [ -f "${TEMP_INSTALLED_PKGS}" ]; then
        log_info "Installed packages list: $(cat ${TEMP_INSTALLED_PKGS})"
    fi
    
    log_error "Check logs at: ${LOGFILE}"
    log_error "Installation aborted."
    exit 1
}

trap cleanup_on_error ERR

# ============================================================================
# PACKAGE MANAGEMENT FUNCTIONS
# ============================================================================

is_package_installed() {
    pacman -Qi "$1" &>/dev/null
    return $?
}

is_aur_package_installed() {
    if command -v yay &>/dev/null; then
        yay -Qi "$1" &>/dev/null
        return $?
    else
        return 1
    fi
}

install_package() {
    local pkg="$1"
    local pkg_manager="${2:-pacman}"
    
    if is_package_installed "${pkg}"; then
        log_info "${pkg} (already installed)"
        return 0
    fi
    
    if [ "${pkg_manager}" = "pacman" ]; then
        if sudo pacman -S --noconfirm --needed "${pkg}" >> "${LOGFILE}" 2>&1; then
            echo "${pkg}" >> "${TEMP_INSTALLED_PKGS}"
            log_success "${pkg}"
            return 0
        else
            log_error "Failed to install package '${pkg}'"
            return 1
        fi
    elif [ "${pkg_manager}" = "yay" ]; then
        if is_aur_package_installed "${pkg}"; then
            log_info "${pkg} (already installed)"
            return 0
        fi
        
        if yay -S --noconfirm --answerdiff None --answerclean None "${pkg}" >> "${LOGFILE}" 2>&1; then
            echo "${pkg}" >> "${TEMP_INSTALLED_PKGS}"
            log_success "${pkg}"
            return 0
        else
            log_error "Failed to install AUR package '${pkg}'"
            return 1
        fi
    fi
}

install_package_group() {
    local group_name="$1"
    local pkg_manager="${2:-pacman}"
    shift 2
    local packages=("$@")
    
    echo ""
    log_info "════════════════════════════════════════════════════════════"
    log_info " ${BOLD}${CYAN}${group_name}${NC}"
    log_info "════════════════════════════════════════════════════════════"
    
    local failed_packages=()
    
    for pkg in "${packages[@]}"; do
        # Skip empty lines and comments
        [[ -z "${pkg}" || "${pkg}" =~ ^[[:space:]]*# ]] && continue
        
        if ! install_package "${pkg}" "${pkg_manager}"; then
            failed_packages+=("${pkg}")
        fi
    done
    
    if [ ${#failed_packages[@]} -ne 0 ]; then
        log_error "Failed to install packages in group '${group_name}': ${failed_packages[*]}"
        return 1
    fi
    
    log_success "Package group '${group_name}' completed"
    return 0
}

# ============================================================================
# SYSTEM UPDATE
# ============================================================================

update_system() {
    log_info "=========================================="
    log_info "Updating system"
    log_info "=========================================="
    
    if sudo pacman -Syu --noconfirm; then
        log_success "System updated successfully"
    else
        log_error "Failed to update system"
        return 1
    fi
}

# ============================================================================
# INITIAL SETUP
# ============================================================================

initial_setup() {
    log_info "=========================================="
    log_info "Running initial setup"
    log_info "=========================================="
    
    # Enable rfkill-unblock
    if sudo systemctl enable rfkill-unblock@all; then
        log_success "Enabled rfkill-unblock@all"
    else
        log_warning "Failed to enable rfkill-unblock@all (may not exist on this system)"
    fi
    
    # Install essential packages
    install_package "archlinux-keyring" "pacman"
    install_package "sed" "pacman"
    
    # Run pacman configuration
    if [ -f "${SCRIPT_DIR}/install/pacman.sh" ]; then
        log_info "Configuring pacman..."
        if bash "${SCRIPT_DIR}/install/pacman.sh"; then
            log_success "Pacman configured successfully"
        else
            log_error "Failed to configure pacman"
            return 1
        fi
    fi
}

# ============================================================================
# INSTALL PACKAGES FROM FILE
# ============================================================================

install_packages_from_file() {
    log_info "=========================================="
    log_info "Installing packages from pkgs.txt"
    log_info "=========================================="
    
    local pkgs_file="${SCRIPT_DIR}/install/pkgs.txt"
    
    if [ ! -f "${pkgs_file}" ]; then
        log_error "Package file not found: ${pkgs_file}"
        return 1
    fi
    
    # Read packages and categorize them by group comments
    local current_group=""
    local -A package_groups
    
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines
        [[ -z "${line}" ]] && continue
        
        # Check if line is a group comment
        if [[ "${line}" =~ ^#[[:space:]](.+)$ ]]; then
            current_group="${BASH_REMATCH[1]}"
            package_groups["${current_group}"]=""
            continue
        fi
        
        # Skip other comments
        [[ "${line}" =~ ^# ]] && continue
        
        # Add package to current group
        if [[ -n "${current_group}" ]]; then
            package_groups["${current_group}"]+="${line} "
        fi
    done < "${pkgs_file}"
    
    # Install packages by groups in order
    local group_order=(
        "Base Development Tools"
        "System Tools & Utilities"
        "Xorg Display Server"
        "Audio System (Pipewire)"
        "Network Management"
        "i3 Window Manager & Compositor"
        "Desktop Utilities"
        "Fonts & Themes"
        "Applications"
    )
    
    for group_name in "${group_order[@]}"; do
        if [[ -n "${package_groups[$group_name]:-}" ]]; then
            local pkgs_array=(${package_groups[$group_name]})
            install_package_group "${group_name}" "pacman" "${pkgs_array[@]}" || return 1
        fi
    done
    
    log_success "All packages from pkgs.txt installed successfully"
}

# ============================================================================
# RUN INSTALL SCRIPTS
# ============================================================================

run_install_scripts() {
    echo ""
    log_info "════════════════════════════════════════════════════════════"
    log_info " ${BOLD}${MAGENTA}Additional Components Installation${NC}   " 
    log_info "════════════════════════════════════════════════════════════"
    
    # Load user preferences if available
    if [ -f /tmp/dotfiles-user-prefs.conf ]; then
        source /tmp/dotfiles-user-prefs.conf
        log_info "Loaded user preferences"
    else
        # Default values
        INSTALL_NVIM="yes"
        INSTALL_NVCHAD="yes"
        INSTALL_LAPTOP="no"
    fi
    
    # i3lock-color needs to be built from source, run it silently with only log output
    local i3lock_script="${SCRIPT_DIR}/install/i3lock-color-install.sh"
    if [ -f "${i3lock_script}" ]; then
        log_info "Building i3lock-color from source (this may take a moment)..."
        if bash "${i3lock_script}" >> "${LOGFILE}" 2>&1; then
            log_success "i3lock-color installed successfully"
        else
            log_error "Failed to install i3lock-color (check logs)"
            return 1
        fi
    fi
    
    # Install yay silently
    local yay_script="${SCRIPT_DIR}/install/yay-install.sh"
    if [ -f "${yay_script}" ]; then
        log_info "Installing yay (AUR helper)..."
        if bash "${yay_script}" >> "${LOGFILE}" 2>&1; then
            log_success "yay installed successfully"
        else
            log_error "Failed to install yay (check logs)"
            return 1
        fi
    fi
    
    # Install Firefox configuration silently
    local firefox_script="${SCRIPT_DIR}/install/firefox.sh"
    if [ -f "${firefox_script}" ]; then
        log_info "Configuring Firefox with pywalfox..."
        if bash "${firefox_script}" >> "${LOGFILE}" 2>&1; then
            log_success "Firefox configured successfully"
        else
            log_error "Failed to configure Firefox (check logs)"
            return 1
        fi
    fi
    
    # Add nvchad script if user wants it
    if [[ "${INSTALL_NVCHAD}" == "yes" ]]; then
        local nvchad_script="${SCRIPT_DIR}/install/nv-chad-install.sh"
        if [ -f "${nvchad_script}" ]; then
            log_info "Installing NvChad..."
            if bash "${nvchad_script}" >> "${LOGFILE}" 2>&1; then
                log_success "NvChad installed successfully"
            else
                log_error "Failed to install NvChad (check logs)"
                return 1
            fi
        fi
    fi
    
    # Add vim
    local vim_script="${SCRIPT_DIR}/install/vim-install.sh"
    if [ -f "${vim_script}" ]; then
        log_info "Installing Vim with plugins..."
        if bash "${vim_script}" >> "${LOGFILE}" 2>&1; then
            log_success "Vim installed successfully"
        else
            log_error "Failed to install Vim (check logs)"
            return 1
        fi
    fi

    # Add laptop script if user has a laptop
    if [[ "${INSTALL_LAPTOP}" == "yes" ]]; then
        local laptop_script="${SCRIPT_DIR}/install/laptop.sh"
        if [ -f "${laptop_script}" ]; then
            log_info "Installing laptop optimizations (TLP, acpid)..."
            if bash "${laptop_script}" >> "${LOGFILE}" 2>&1; then
                log_success "Laptop optimizations installed successfully"
            else
                log_error "Failed to install laptop optimizations (check logs)"
                return 1
            fi
        fi
    fi
    
    # Install matugen-bin via yay
    if command -v yay &>/dev/null; then
        install_package "matugen-bin" "yay" || return 1
    else
        log_warning "yay not found, skipping matugen-bin installation"
    fi

    # Install Zsh
    local zsh_script="${SCRIPT_DIR}/install/zsh-install.sh"
    if [ -f "${zsh_script}" ]; then
        log_info "Configuring Zsh..."
        if bash "${zsh_script}" >> "${LOGFILE}" 2>&1; then
            log_success "Zsh configured successfully"
        else
            log_error "Failed to configure Zsh (check logs)"
            return 1
        fi
    fi

}

# ============================================================================
# COPY CONFIGURATION FILES
# ============================================================================

copy_config_files() {
    log_info "=========================================="
    log_info "Copying configuration files"
    log_info "=========================================="
    
    local config_dir="${SCRIPT_DIR}/config"
    
    if [ ! -d "${config_dir}" ]; then
        log_error "Config directory not found: ${config_dir}"
        return 1
    fi
    
    if cp -a "${config_dir}/." ~/; then
        log_success "Configuration files copied successfully"
    else
        log_error "Failed to copy configuration files"
        return 1
    fi
}

# ============================================================================
# SYSTEM SERVICES
# ============================================================================

enable_services() {
    log_info "=========================================="
    log_info "Enabling and starting services"
    log_info "=========================================="
    
    # NetworkManager
    if sudo systemctl enable NetworkManager.service && sudo systemctl start NetworkManager.service; then
        log_success "NetworkManager enabled and started"
    else
        log_error "Failed to enable NetworkManager"
        return 1
    fi
    
    # wpa_supplicant
    if sudo systemctl enable wpa_supplicant.service && sudo systemctl start wpa_supplicant.service; then
        log_success "wpa_supplicant enabled and started"
    else
        log_warning "Failed to enable wpa_supplicant (may not be needed)"
    fi
    
    # Pipewire
    if systemctl --user enable pipewire-pulse.service && systemctl --user enable wireplumber.service; then
        log_success "Pipewire services enabled"
    else
        log_error "Failed to enable Pipewire services"
        return 1
    fi
    
    # ly display manager
    if sudo systemctl enable ly.service; then
        log_success "ly display manager enabled"
    else
        log_warning "Failed to enable ly (may need to be installed separately)"
    fi
}

# ============================================================================
# FINALIZATION
# ============================================================================

finalize_setup() {
    log_info "=========================================="
    log_info "Finalizing setup"
    log_info "=========================================="
    
    # Set GTK theme
    export GTK_THEME="Adwaita:dark"
    log_info "GTK theme set to Adwaita:dark"
    
    # Update font cache
    if fc-cache -f; then
        log_success "Font cache updated"
    else
        log_warning "Failed to update font cache"
    fi
    
    # Create background script
    log_info "Creating background script..."
    cat > ~/.bg << 'EOF'
#!/bin/sh
~/.config/scripts/change_wallpapers.sh ~/.wallpapers/default.jpg
EOF
    chmod +x ~/.bg
    log_success "Background script created"
    
    # Create a self-destructing autostart script for first wallpaper setup
    log_info "Creating first-run wallpaper setup..."
    cat > ~/.config/i3/autostart_once.sh << 'EOF'
#!/bin/bash
# This script runs once and removes itself completely

if [ -f ~/.wallpapers/default.jpg ] && [ -x ~/.config/scripts/change_wallpaper.sh ]; then
    ~/.config/scripts/change_wallpaper.sh ~/.wallpapers/default.jpg
fi

# Remove the exec line from i3 config
sed -i '/exec.*autostart_once\.sh/d' ~/.config/i3/config

# Remove this script
rm -f ~/.config/i3/autostart_once.sh
i3 restart
pywalfox update
EOF
    
    chmod +x ~/.config/i3/autostart_once.sh
    
    # Add exec to i3 config (will be removed by the script itself)
    echo "exec_always --no-startup-id ~/.config/i3/autostart_once.sh" >> ~/.config/i3/config
    
    log_success "First-run setup configured (will auto-remove after first i3 startup)"
}

# ============================================================================
# MAIN INSTALLATION FUNCTION
# ============================================================================

main() {
    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║                                                            ║${NC}"
    echo -e "${BOLD}${CYAN}║     Arch Linux Dotfiles Installation Script                ║${NC}"
    echo -e "${BOLD}${CYAN}║                                                            ║${NC}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    log_info "Installation log: ${LOGFILE}"
    echo ""
    
    # Initialize temp file
    > "${TEMP_INSTALLED_PKGS}"
    
    # Run user preferences FIRST
    local user_prefs="${SCRIPT_DIR}/install/user-preferences.sh"
    if [ -f "${user_prefs}" ]; then
        chmod +x "${user_prefs}"
        if bash "${user_prefs}"; then
            log_success "User preferences configured"
        else
            log_error "Failed to configure user preferences"
            exit 1
        fi
    fi
    
    # Run installation steps
    update_system || exit 1
    initial_setup || exit 1
    install_packages_from_file || exit 1
    copy_config_files || exit 1
    run_install_scripts || exit 1
    enable_services || exit 1
    finalize_setup || exit 1
    
    # Cleanup temp file
    rm -f "${TEMP_INSTALLED_PKGS}"
    
    echo ""
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║                                                            ║${NC}"
    echo -e "${BOLD}${GREEN}║          Installation Completed Successfully!              ║${NC}"
    echo -e "${BOLD}${GREEN}║                                                            ║${NC}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    log_info "Please reboot your system to apply all changes"
    log_info "Logs available at: ${LOGFILE}"
    echo ""
}

# ============================================================================
# SCRIPT ENTRY POINT
# ============================================================================

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Do not run this script as root. Use a regular user with sudo privileges."
    exit 1
fi

# Create log file if it doesn't exist
sudo touch "${LOGFILE}"
sudo chmod 666 "${LOGFILE}"

# Run main installation
main
