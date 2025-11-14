#!/bin/sh

yay -S --noconfirm --answerdiff None --answerclean None python-pywalfox && \
sudo pywalfox install && \
sudo mkdir -p /etc/firefox/policies/ && \
sudo sh -c 'echo "{\"policies\": {\"ExtensionSettings\": {\"pywalfox@frewacom.org\": {\"installation_mode\": \"normal_installed\", \"install_url\": \"https://addons.mozilla.org/firefox/downloads/latest/pywalfox@frewacom.org/latest.xpi\"}}}}" > /etc/firefox/policies/policies.json'
