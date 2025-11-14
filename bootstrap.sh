#!/bin/bash

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

clear
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        Arch Linux Configuration Installer                ║
║                                                           ║
║  This will install a complete system with i3wm,          ║
║  polybar, neovim and all necessary tools.                ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF

echo ""
echo -e "${BLUE}[INFO]${NC} Starting installation..."
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}[✗]${NC} Do not run this script as root"
    exit 1
fi

# Install git if not present
if ! command -v git &>/dev/null; then
    echo -e "${BLUE}[INFO]${NC} Installing git..."
    sudo pacman -Sy --noconfirm git
    echo -e "${GREEN}[✓]${NC} Git installed"
fi

# Clone repository
REPO_URL="https://github.com/tsunooky/dotfiles.git"
INSTALL_DIR="/tmp/dotfiles-install-$$"

echo -e "${BLUE}[INFO]${NC} Cloning repository..."

if git clone "$REPO_URL" "$INSTALL_DIR"; then
    echo -e "${GREEN}[✓]${NC} Repository cloned successfully"
else
    echo -e "${RED}[✗]${NC} Failed to clone repository"
    exit 1
fi

# Navigate to directory and run installation
cd "$INSTALL_DIR"

# Make scripts executable
chmod +x install.sh
chmod +x install/*.sh 2>/dev/null || true

echo ""
echo -e "${CYAN}Starting main installation...${NC}"
echo ""

# Execute the main installer
exec bash ./install.sh
