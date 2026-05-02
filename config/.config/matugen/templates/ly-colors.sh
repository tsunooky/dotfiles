#!/bin/sh
# Matugen TTY Background Color
# This script is called by ly.service via ExecStartPre

# We only modify color 0 (background) and color 7 (foreground/white)
# \033]P0RRGGBB sets background
# \033]P7ffffff sets foreground to white
# \033c refreshes the TTY
printf "\033]P0{{colors.surface.default.hex_stripped}}\033]P7ffffff\033c" > /dev/tty2
