#!/bin/bash

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Paths
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_DIR="/tmp/dotfiles-install"
readonly LOG_FILE="${LOG_DIR}/install.log"
readonly ERROR_LOG="${LOG_DIR}/errors.log"
readonly BACKUP_DIR="${LOG_DIR}/backup"
readonly FAILED_PACKAGES_FILE="${LOG_DIR}/failed_packages.txt"

# Installation state
INSTALL_FAILED=0
declare -a FAILED_PACKAGES=()

# Create necessary directories
mkdir -p "$LOG_DIR" "$BACKUP_DIR"
: > "$LOG_FILE"
: > "$ERROR_LOG"
: > "$FAILED_PACKAGES_FILE"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        INFO)
            echo -e "${BLUE}[INFO]${NC} $message" | tee -a "$LOG_FILE"
            ;;
        SUCCESS)
            echo -e "${GREEN}[✓]${NC} $message" | tee -a "$LOG_FILE"
            ;;
        WARNING)
            echo -e "${YELLOW}[⚠]${NC} $message" | tee -a "$LOG_FILE"
            ;;
        ERROR)
            echo -e "${RED}[✗]${NC} $message" | tee -a "$LOG_FILE" "$ERROR_LOG"
            ;;
        STEP)
            echo -e "\n${PURPLE}==>${NC} ${CYAN}$message${NC}\n" | tee -a "$LOG_FILE"
            ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Cleanup function
cleanup_on_error() {
    local exit_code=$?
    
    log ERROR "Installation failed with exit code: $exit_code"
    log ERROR "Cleaning up..."
    
    # Restore backups
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        log INFO "Restoring configuration backups..."
        cp -rf "$BACKUP_DIR"/* ~/ 2>/dev/null || true
        log SUCCESS "Backups restored"
    fi
    
    # Clean up temporary installation directory
    cd ~
    if [[ "${SCRIPT_DIR}" == /tmp/* ]]; then
        log INFO "Removing temporary installation files..."
        rm -rf "${SCRIPT_DIR}" 2>/dev/null || true
    fi
    
    # Clean up any partial yay installation
    if [ -d ~/yay-bin ]; then
        log INFO "Cleaning up yay installation..."
        rm -rf ~/yay-bin
    fi
    
    # Clean up i3lock-color build directory
    if [ -d /tmp/i3lock-color ]; then
        log INFO "Cleaning up i3lock-color build directory..."
        sudo rm -rf /tmp/i3lock-color 2>/dev/null || true
    fi
    
    log INFO "Logs saved in: $LOG_DIR"
    log INFO "Error log: $ERROR_LOG"
    
    if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
        log ERROR "Failed packages:"
        printf '%s\n' "${FAILED_PACKAGES[@]}" | tee -a "$FAILED_PACKAGES_FILE"
    fi
    
    echo ""
    log ERROR "Installation aborted. System has been cleaned up."
    
    exit 1
}

# Trap errors - stop on any error
trap cleanup_on_error ERR INT TERM
set -e

# Check if package is installed
is_installed() {
    pacman -Qi "$1" &>/dev/null
}

# Install single package with retry and live output
install_package() {
    local package="$1"
    local max_retries=3
    local retry=0
    
    if is_installed "$package"; then
        log SUCCESS "$package (already installed)"
        return 0
    fi
    
    # Use a spinner/progress line that gets overwritten
    printf "\r${BLUE}[INFO]${NC} Installing $package...                    "
    
    while [ $retry -lt $max_retries ]; do
        # Show live pacman output with progress, download speed, etc.
        if sudo pacman -S --noconfirm --needed "$package" 2>&1 | tee -a "$LOG_FILE"; then
            # Clear the line and show success
            printf "\r\033[K"
            log SUCCESS "$package"
            return 0
        else
            retry=$((retry + 1))
            if [ $retry -lt $max_retries ]; then
                log WARNING "Failed to install $package. Retry $retry/$max_retries..."
                sleep 2
            fi
        fi
    done
    
    log ERROR "Failed to install $package after $max_retries attempts"
    FAILED_PACKAGES+=("$package")
    return 1
}

# Install list of packages
install_packages() {
    local category="$1"
    shift
    local packages=("$@")
    local failed_in_category=()
    
    log STEP "Installing packages: $category"
    
    for package in "${packages[@]}"; do
        if ! install_package "$package"; then
            failed_in_category+=("$package")
            INSTALL_FAILED=1
        fi
    done
    
    if [ ${#failed_in_category[@]} -gt 0 ]; then
        log ERROR "Failed to install packages in $category:"
        for pkg in "${failed_in_category[@]}"; do
            log ERROR "  - $pkg"
        done
        
        echo ""
        log ERROR "Critical packages failed. Installation cannot continue."
        cleanup_on_error
    fi
}

# Run installation script with live output (shows last 3 lines, unbuffered)
run_script() {
    local script="$1"
    local description="$2"
    local optional="${3:-false}"
    
    if [ ! -f "$script" ]; then
        log ERROR "Script not found: $script"
        if [ "$optional" = "true" ]; then
            log WARNING "Skipping optional script"
            return 0
        fi
        return 1
    fi
    
    log STEP "$description"
    
    chmod +x "$script"
    
    # Create temporary file for output
    local tmp_output=$(mktemp)
    local last_size=0
    
    # Run script in background with unbuffered output
    stdbuf -oL -eL bash "$script" > "$tmp_output" 2>&1 &
    local pid=$!
    
    # Reserve space for 3 lines
    echo ""
    echo ""
    echo ""
    
    # Monitor progress - show last 3 lines
    while kill -0 $pid 2>/dev/null; do
        local current_size=$(stat -c%s "$tmp_output" 2>/dev/null || echo "0")
        
        # Only update if file has grown
        if [ "$current_size" -gt "$last_size" ]; then
            # Move cursor up 3 lines and clear them
            printf "\033[3A"
            printf "\033[J"
            
            # Show last 3 lines with indentation
            tail -n 3 "$tmp_output" 2>/dev/null | while IFS= read -r line; do
                echo "  $line"
            done
            
            last_size=$current_size
        fi
        
        sleep 0.3
    done
    
    # Wait for process to finish
    wait $pid
    local exit_code=$?
    
    # Move cursor up 3 lines and clear
    printf "\033[3A"
    printf "\033[J"
    
    # Save to log
    cat "$tmp_output" >> "$LOG_FILE"
    rm -f "$tmp_output"
    
    if [ $exit_code -eq 0 ]; then
        log SUCCESS "$description completed"
        return 0
    else
        log ERROR "Failed: $description (exit code: $exit_code)"
        log ERROR "Check $LOG_FILE for details"
        
        if [ "$optional" = "true" ]; then
            log WARNING "Optional script failed, continuing..."
            return 0
        fi
        
        return 1
    fi
}

# Backup file or directory
backup_file() {
    local file="$1"
    if [ -f "$file" ] || [ -d "$file" ]; then
        local backup_path="$BACKUP_DIR/$(basename "$file")"
        cp -rf "$file" "$backup_path" 2>/dev/null || true
        log INFO "Backup: $file"
    fi
}

# Display banner
clear
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        Arch Linux Configuration Installer                 ║
║                                                           ║
║  This will install a complete system with i3wm,           ║
║  polybar, neovim and all necessary tools.                 ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF

echo ""
log INFO "Installation logs: $LOG_FILE"
log INFO "Error logs: $ERROR_LOG"
log INFO "Backups: $BACKUP_DIR"
echo ""

read -p "Do you want to continue? [Y/n] " response < /dev/tty
if [[ "$response" =~ ^[nN]$ ]]; then
    log INFO "Installation cancelled"
    exit 0
fi

# Use current directory (repository should already be cloned by bootstrap.sh)
log STEP "Preparing installation"

REPO_DIR="${SCRIPT_DIR}"
cd "$REPO_DIR"

# Verify we have the necessary files
if [ ! -d "install" ] || [ ! -d "config" ]; then
    log ERROR "Installation files not found. Make sure you're running from the dotfiles directory."
    exit 1
fi

log SUCCESS "Configuration files ready"

# Update system
log STEP "Updating system"
if ! sudo pacman -Syu --noconfirm >> "$LOG_FILE" 2>> "$ERROR_LOG"; then
    log WARNING "System update failed, continuing anyway..."
fi

# Enable rfkill unblock
sudo systemctl enable rfkill-unblock@all 2>/dev/null || true

# Install base packages
install_packages "Base System" archlinux-keyring sed

# Configure pacman
log STEP "Configuring pacman"
run_script "./install/pacman.sh" "Pacman configuration"

# System packages
install_packages "System Core" \
    linux linux-firmware grub efibootmgr \
    base-devel glibc gcc make git git-lfs

install_packages "System Utilities" \
    man-pages man-db nano vim openssh \
    fuse3 os-prober ntfs-3g curl wget \
    sed grep awk ripgrep tar unzip unrar gzip p7zip bash-completion

# Xorg
install_packages "Xorg Display Server" \
    xorg-server xorg-xinit xorg-xrandr

# Audio
install_packages "Audio System" \
    pipewire pipewire-alsa pipewire-pulse \
    wireplumber pavucontrol alsa-utils

# Network
install_packages "Network Tools" \
    networkmanager network-manager-applet \
    wpa_supplicant iw dialog blueman

# i3 and desktop components
install_packages "i3 Window Manager" \
    i3-wm xss-lock picom autotiling polybar rofi

install_packages "Desktop Tools" \
    brightnessctl dunst libnotify feh scrot \
    thunar thunar-volman gvfs gvfs-mtp \
    lxappearance acpi flameshot

# Themes and fonts
install_packages "Themes and Fonts" \
    fontconfig gtk3 gtk4 adw-gtk-theme \
    papirus-icon-theme lsd starship \
    ttf-jetbrains-mono-nerd noto-fonts \
    noto-fonts-extra noto-fonts-emoji noto-fonts-cjk

# Applications
install_packages "Applications" \
    alacritty firefox vim \
    python imagemagick xsel fastfetch ncdu bat yazi zathura

# Ask about Neovim
echo ""
log STEP "Editor Configuration"
read -p "Do you want to install Neovim? [Y/n] " nvim_response < /dev/tty
nvim_response="${nvim_response:-y}"
nvim_response=$(echo "$nvim_response" | tr '[:upper:]' '[:lower:]')

USE_NVCHAD=false

if [[ "$nvim_response" == "y" ]] || [[ "$nvim_response" == "yes" ]]; then
    install_packages "Neovim" neovim
    
    echo ""
    read -p "Do you want to install NvChad configuration? [Y/n] " nvchad_response < /dev/tty
    nvchad_response="${nvchad_response:-y}"
    nvchad_response=$(echo "$nvchad_response" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$nvchad_response" == "y" ]] || [[ "$nvchad_response" == "yes" ]]; then
        USE_NVCHAD=true
        log INFO "NvChad will be installed"
    else
        log INFO "Neovim will be installed without NvChad"
    fi
else
    log INFO "Neovim will not be installed"
fi

# Development tools
install_packages "Development Tools" \
    gdb clang valgrind criterion

# Display manager
install_packages "Display Manager" ly

# Custom installations - i3lock-color with detailed logging
log STEP "Compiling i3lock-color"
log INFO "This may take a few minutes..."
log INFO "Installing build dependencies..."
run_script "./install/i3lock-color-install.sh" "i3lock-color compilation"

# AUR helper installation
log STEP "Installing AUR helper (yay)"
log INFO "Cloning and building yay from AUR..."
run_script "./install/yay-install.sh" "AUR helper (yay)"

# Install AUR packages
log STEP "Installing AUR packages"
if command -v yay &>/dev/null; then
    log INFO "Installing matugen-bin for color scheme generation..."
    if yay -S --noconfirm --answerdiff None --answerclean None matugen-bin 2>&1 | tee -a "$LOG_FILE"; then
        log SUCCESS "matugen-bin installed"
    else
        log WARNING "Failed to install matugen-bin"
        log WARNING "Color scheme generation may not work"
    fi
else
    log WARNING "yay not available, skipping AUR packages"
fi

# NvChad installation
if [ "$USE_NVCHAD" = true ]; then
    log STEP "Installing NvChad"
    log INFO "Backing up existing Neovim configuration..."
    log INFO "Cloning NvChad repository..."
    run_script "./install/nv-chad-install.sh" "NvChad configuration"
else
    log INFO "Skipping NvChad installation"
fi

# Backup existing configs
log STEP "Backing up existing configurations"
backup_file ~/.config
backup_file ~/.bashrc
backup_file ~/.vimrc
backup_file ~/.Xresources

# Copy configurations
log STEP "Installing configuration files"
if [ -d "config" ]; then
    cp -rf config/. ~/
    log SUCCESS "Configuration files copied"
else
    log ERROR "Config directory not found"
fi

# Vim plugins (always installed)
log STEP "Installing Vim plugins"
log INFO "Installing Vundle plugin manager..."
run_script "./install/vim-install.sh" "Vim plugins"

# User preferences
log STEP "User preferences configuration"
chmod +x ./install/user-preferences.sh
bash ./install/user-preferences.sh

# System services
log STEP "Enabling system services"

sudo systemctl enable NetworkManager.service
sudo systemctl start NetworkManager.service || true
sudo systemctl enable wpa_supplicant.service
sudo systemctl start wpa_supplicant.service || true

systemctl --user enable pipewire-pulse.service || true
systemctl --user enable wireplumber.service || true

sudo systemctl enable ly.service

log SUCCESS "System services configured"

# Final setup
log STEP "Final configuration"

export GTK_THEME="Adwaita:dark"
fc-cache -f

# Set executable permissions for scripts
find ~/.config/scripts -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# Cleanup - remove temporary installation directory
cd ~
if [[ "$REPO_DIR" == /tmp/* ]]; then
    log INFO "Cleaning up temporary files..."
    rm -rf "$REPO_DIR"
fi

# Summary
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
if [ $INSTALL_FAILED -eq 0 ]; then
    echo -e "║  ${GREEN}✓ Installation completed successfully!${NC}                   ║"
else
    echo -e "║  ${YELLOW}⚠ Installation completed with warnings${NC}                  ║"
fi
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

log INFO "Summary:"
log INFO "  - Installation logs: $LOG_FILE"
log INFO "  - Error logs: $ERROR_LOG"
log INFO "  - Configuration backups: $BACKUP_DIR"

if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
    echo ""
    log WARNING "The following packages failed to install:"
    printf '%s\n' "${FAILED_PACKAGES[@]}"
    log INFO "You can manually install them later with:"
    log INFO "  sudo pacman -S ${FAILED_PACKAGES[*]}"
    echo ""
fi

echo ""
log WARNING "Please reboot your system to apply all changes"
echo ""

read -p "Reboot now? [y/N] " reboot_response < /dev/tty
if [[ "$reboot_response" =~ ^[yY]$ ]]; then
    sudo reboot
fi
