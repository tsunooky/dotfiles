#!/bin/bash

FAILED=false

if command -v yay &> /dev/null; then
    yay -S --noconfirm --needed python-pywalfox || FAILED=true
else
    echo "Error: yay is not installed."
    FAILED=true
fi

sudo pywalfox install || FAILED=true

POLICIES_DIR="/etc/firefox/policies"
sudo mkdir -p "$POLICIES_DIR"

echo "Configuring Firefox policies..."

sudo tee "$POLICIES_DIR/policies.json" > /dev/null <<EOF
{
  "policies": {
    "ExtensionSettings": {
      "pywalfox@frewacom.org": {
        "installation_mode": "normal_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/pywalfox@frewacom.org/latest.xpi"
      }
    }
  }
}
EOF

if [ "$FAILED" = true ]; then
    echo ""
    echo "################################################################"
    echo "WARNING: The automated installation encountered some issues."
    echo "Please install the Pywalfox extension manually from the"
    echo "official Firefox Add-ons store to ensure it works correctly."
    echo "################################################################"
    echo ""
fi

exit 0
