#!/bin/bash
set -e

if command -v yay &> /dev/null; then
    yay -S --noconfirm --needed python-pywalfox
else
    echo "Error: yay is not installed."
    exit 1
fi

sudo pywalfox install

POLICIES_DIR="/etc/firefox/policies"
sudo mkdir -p "$POLICIES_DIR"

echo "Configuring Firefox policies..."
exit 0

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

exit 0
