#!/bin/sh
# Matugen TTY Color Palette
# This script sets the TTY colors using printf escape codes

# Use absolute paths and broadcast to console for Ly compatibility
set_colors() {
    # index 0: Background (surface_container_high)
    printf "\033]P0{{colors.surface_container_high.default.hex_stripped}}"
    # index 1: Error (Red)
    printf "\033]P1{{colors.error.default.hex_stripped}}"
    # index 2: Border (Primary)
    printf "\033]P2{{colors.primary.default.hex_stripped}}"
    # index 3: Secondary (Yellow)
    printf "\033]P3{{colors.secondary.default.hex_stripped}}"
    # index 4: Tertiary (Blue)
    printf "\033]P4{{colors.tertiary.default.hex_stripped}}"
    # index 5: Magenta
    printf "\033]P5{{colors.primary_container.default.hex_stripped}}"
    # index 6: Labels (Primary for visibility)
    printf "\033]P6{{colors.primary.default.hex_stripped}}"
    # index 7: Foreground (on_surface)
    printf "\033]P7{{colors.on_surface.default.hex_stripped}}"
    
    # Refresh terminal
    printf "\033c"
}

# Run for current shell
set_colors

# If root (Ly), force it onto /dev/tty2 and /dev/console
if [ "$(id -u)" -eq 0 ]; then
    set_colors > /dev/tty2
    set_colors > /dev/console
fi
