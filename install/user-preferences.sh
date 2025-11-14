#!/bin/bash

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

# Force input from terminal
exec < /dev/tty

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║              User Preferences Configuration               ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Set 4K configuration
set_4k() {
    echo -e "${BLUE}[INFO]${NC} Configuring for 4K display..."
    
    # Set DPI for polybar
    if [ -f ~/.config/polybar/config.ini ]; then
        sed -i "s/{{DPI}}/192/g" ~/.config/polybar/config.ini
    fi
    
    # Create Xresources
    cat > ~/.Xresources << 'EOF'
Xft.dpi: 192
Xft.autohint: 0
Xft.lcdfilter: lcddefault
Xft.hintstyle: hintfull
Xft.hinting: 1
Xft.antialias: 1
Xft.rgba: rgb
EOF
    
    echo -e "${GREEN}[✓]${NC} 4K configuration applied (DPI: 192)"
}

# Set custom DPI
set_custom_dpi() {
    local dpi="$1"
    
    echo -e "${BLUE}[INFO]${NC} Configuring custom DPI: $dpi..."
    
    # Set DPI for polybar
    if [ -f ~/.config/polybar/config.ini ]; then
        sed -i "s/{{DPI}}/$dpi/g" ~/.config/polybar/config.ini
    fi
    
    # Create Xresources
    cat > ~/.Xresources << EOF
Xft.dpi: $dpi
Xft.autohint: 0
Xft.lcdfilter: lcddefault
Xft.hintstyle: hintfull
Xft.hinting: 1
Xft.antialias: 1
Xft.rgba: rgb
EOF
    
    echo -e "${GREEN}[✓]${NC} Custom DPI configuration applied: $dpi"
}

# Validate DPI input
is_valid_dpi() {
    local dpi="$1"
    
    if [[ "$dpi" =~ ^[0-9]+$ ]] && [ "$dpi" -ge 72 ] && [ "$dpi" -le 300 ]; then
        return 0
    else
        return 1
    fi
}

# Main configuration
echo -e "${CYAN}Display Configuration${NC}"
echo "──────────────────────────────────────────────────────────"
echo ""

# Ask about 4K monitor
while true; do
    read -p "Are you using a 4K monitor? [Y/n] " response_4k
    
    # Default to yes if empty
    response_4k="${response_4k:-y}"
    
    # Convert to lowercase
    response_4k=$(echo "$response_4k" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$response_4k" == "y" ]] || [[ "$response_4k" == "yes" ]]; then
        set_4k
        break
    elif [[ "$response_4k" == "n" ]] || [[ "$response_4k" == "no" ]]; then
        echo ""
        echo "Common DPI values:"
        echo "  - 96   (Standard 1080p)"
        echo "  - 120  (1.25x scaling)"
        echo "  - 144  (1.5x scaling - 2K)"
        echo "  - 192  (2x scaling - 4K)"
        echo ""
        
        while true; do
            read -p "Enter your desired DPI (72-300) [default: 96]: " response_dpi
            
            # Default to 96 if empty
            response_dpi="${response_dpi:-96}"
            
            if is_valid_dpi "$response_dpi"; then
                set_custom_dpi "$response_dpi"
                break 2
            else
                echo -e "${RED}[✗]${NC} Invalid DPI. Please enter a number between 72 and 300."
            fi
        done
    else
        echo "Please answer 'y' for yes or 'n' for no."
    fi
done

echo ""
echo "──────────────────────────────────────────────────────────"
echo ""

# Additional configurations can be added here
# For example: keyboard layout, timezone, etc.

echo -e "${GREEN}[✓]${NC} User preferences configured successfully!"
echo ""
