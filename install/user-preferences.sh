#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}$1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
}

setDPI() {
    local dpi="$1"
    
    if [ -f ~/.config/polybar/config.ini ]; then
        sed -i "s/{{DPI}}/${dpi}/g" ~/.config/polybar/config.ini
    else
        log_error "Polybar config not found at ~/.config/polybar/config.ini"
        return 1
    fi
    
    echo "Xft.dpi: ${dpi}
Xft.autohint: 0
Xft.lcdfilter: lcddefault
Xft.hintstyle: hintfull
Xft.hinting: 1
Xft.antialias: 1
Xft.rgba: rgb" > ~/.Xresources
    
    log_success "DPI set to ${dpi}"
}

# Ensure we're reading from terminal
exec < /dev/tty

echo ""
log_info "=========================================="
log_info "User Preferences Configuration"
log_info "=========================================="
echo ""

# Ask about Neovim
read -p "Do you want to install Neovim? [Y/n] " response_nvim
response_nvim_lower=${response_nvim,,}

INSTALL_NVIM="yes"
INSTALL_NVCHAD="no"

if [[ "$response_nvim_lower" == "n" ]]; then
    INSTALL_NVIM="no"
    log_info "Neovim will not be installed"
else
    INSTALL_NVIM="yes"
    log_success "Neovim will be installed"
    
    # Ask about NvChad
    read -p "Do you want to install NvChad (Neovim configuration)? [Y/n] " response_nvchad
    response_nvchad_lower=${response_nvchad,,}
    
    if [[ "$response_nvchad_lower" != "n" ]]; then
        INSTALL_NVCHAD="yes"
        log_success "NvChad will be installed"
    else
        INSTALL_NVCHAD="no"
        log_info "NvChad will not be installed"
    fi
fi

echo ""
log_info "------------------------------------------"
log_info "Laptop Configuration"
log_info "------------------------------------------"
echo ""

# Ask if laptop
read -p "Is this a laptop? (installs TLP for battery management) [y/N] " response_laptop
response_laptop_lower=${response_laptop,,}

INSTALL_LAPTOP="no"
if [[ "$response_laptop_lower" == "y" ]]; then
    INSTALL_LAPTOP="yes"
    log_success "Laptop optimizations will be installed"
else
    log_info "Laptop optimizations will not be installed"
fi

echo ""
log_info "------------------------------------------"
log_info "Display Configuration"
log_info "------------------------------------------"
echo ""

echo -e "${YELLOW}Enter your DPI (examples by resolution):${NC}"
echo -e "  1920x1080 (Full HD)      → 96"
echo -e "  2560x1440 (2K)          → 120 or 144"
echo -e "  3840x2160 (4K)          → 192"
echo -e "  3072x1920 (MacBook 16\") → 144 or 192"
echo ""
read -p "Enter DPI [default: 96]: " user_dpi

if [[ -z "$user_dpi" ]]; then
    user_dpi="96"
fi

setDPI "$user_dpi" || exit 1

# Export preferences for setup.sh to use
export USER_PREF_INSTALL_NVIM="${INSTALL_NVIM}"
export USER_PREF_INSTALL_NVCHAD="${INSTALL_NVCHAD}"
export USER_PREF_INSTALL_LAPTOP="${INSTALL_LAPTOP}"

# Save preferences to a file for the main script
cat > /tmp/dotfiles-user-prefs.conf << EOF
INSTALL_NVIM=${INSTALL_NVIM}
INSTALL_NVCHAD=${INSTALL_NVCHAD}
INSTALL_LAPTOP=${INSTALL_LAPTOP}
EOF

echo ""
log_success "User preferences configured successfully"
log_info "Configuration saved to /tmp/dotfiles-user-prefs.conf"
echo ""
