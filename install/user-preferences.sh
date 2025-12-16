#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}$1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
}

setDPI() {
    local dpi="$1"
    
    if [ -f "${SCRIPT_DIR}/config/.config/polybar/config.ini" ]; then
        sed -i "s/{{DPI}}/${dpi}/g" "${SCRIPT_DIR}/config/.config/polybar/config.ini"
    else
        log_error "Polybar config not found at ${SCRIPT_DIR}/config/.config/polybar/config.ini"
        return 1
    fi
    
    echo "Xft.dpi: ${dpi}
Xft.autohint: 0
Xft.lcdfilter: lcddefault
Xft.hintstyle: hintfull
Xft.hinting: 1
Xft.antialias: 1
Xft.rgba: rgb" > ~/.Xresources
    
    log_success "DPI configured to ${dpi} (Resolution based)"
}

exec < /dev/tty

echo ""
log_info "=========================================="
log_info "Auto-detecting Hardware Configuration"
log_info "=========================================="
echo ""

log_info "Checking for laptop battery..."

INSTALL_LAPTOP="no"
if ls /sys/class/power_supply/BAT* 1> /dev/null 2>&1; then
    INSTALL_LAPTOP="yes"
    log_success "Battery detected. System identified as LAPTOP."
    log_info "TLP and laptop optimizations will be installed."
else
    log_info "No battery detected. System identified as DESKTOP."
fi

log_info "Detecting screen resolution..."

DETECTED_DPI="96"

if command -v xrandr >/dev/null 2>&1; then
    CURRENT_RES=$(xrandr 2>/dev/null | grep '*' | awk '{print $1}' | head -n 1)
    
    if [ -n "$CURRENT_RES" ]; then
        SCREEN_WIDTH=$(echo "$CURRENT_RES" | cut -d'x' -f1)
        
        log_info "Detected Resolution: ${CURRENT_RES}"
        
        if [ "$SCREEN_WIDTH" -ge 3000 ]; then
            DETECTED_DPI="192"
        elif [ "$SCREEN_WIDTH" -ge 2100 ]; then
            DETECTED_DPI="144"
        else
            DETECTED_DPI="96"
        fi
    else
        log_warning "xrandr returned no active mode. Defaulting to 96 DPI."
    fi
else
    log_warning "xrandr command not found. Cannot auto-detect DPI. Defaulting to 96 DPI."
fi

setDPI "$DETECTED_DPI" || exit 1

export USER_PREF_INSTALL_LAPTOP="${INSTALL_LAPTOP}"

cat > /tmp/dotfiles-user-prefs.conf << EOF
INSTALL_LAPTOP=${INSTALL_LAPTOP}
EOF

echo ""
log_success "Hardware detection complete."
log_info "Configuration saved to /tmp/dotfiles-user-prefs.conf"
echo ""
