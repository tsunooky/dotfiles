#!/bin/bash

# Remote Installation Script - Clones repo and runs setup
# Compatible with: curl -sSL <raw-github-url> | bash

set -euo pipefail

REPO_URL="https://github.com/tsunooky/dotfiles.git"
INSTALL_DIR="/tmp/dotfiles-install"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}Cloning dotfiles repository...${NC}"

# Check if git is installed
if ! command -v git &>/dev/null; then
    echo -e "${BLUE}Git not found. Installing git...${NC}"
    sudo pacman -Sy --noconfirm git
fi

# Clone repository
if git clone "${REPO_URL}" "${INSTALL_DIR}"; then
    echo -e "${GREEN}✓ Repository cloned${NC}"
else
    echo -e "${RED}✗ Failed to clone repository${NC}"
    exit 1
fi

# Change to install directory
cd "${INSTALL_DIR}"

# Make scripts executable
chmod +x setup.sh install/*.sh

# Run main installation
echo ""
if bash ./setup.sh; then
    echo -e "${GREEN}✓ Installation completed${NC}"
else
    echo -e "${RED}✗ Installation failed${NC}"
    cd ~
    rm -rf "${INSTALL_DIR}"
    exit 1
fi

# Cleanup
cd ~
rm -rf "${INSTALL_DIR}"

echo ""
echo -e "${GREEN}Installation complete! Please reboot your system.${NC}"
echo ""
