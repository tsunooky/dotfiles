#!/bin/sh
# Matugen TTY Color Palette
# This script sets the TTY colors using printf escape codes

if [ "$TERM" = "linux" ]; then
    printf "\033]P0{{colors.surface.default.hex_stripped}}" # Background / Black
    printf "\033]P1{{colors.error.default.hex_stripped}}"   # Red
    printf "\033]P2{{colors.primary.default.hex_stripped}}" # Green
    printf "\033]P3{{colors.secondary.default.hex_stripped}}" # Yellow
    printf "\033]P4{{colors.tertiary.default.hex_stripped}}" # Blue
    printf "\033]P5{{colors.primary_container.default.hex_stripped}}" # Magenta
    printf "\033]P6{{colors.secondary_container.default.hex_stripped}}" # Cyan
    printf "\033]P7{{colors.on_surface.default.hex_stripped}}" # White
    
    # Bright colors
    printf "\033]P8{{colors.outline.default.hex_stripped}}"
    printf "\033]P9{{colors.error_container.default.hex_stripped}}"
    printf "\033]PA{{colors.inverse_primary.default.hex_stripped}}"
    printf "\033]PB{{colors.on_secondary_container.default.hex_stripped}}"
    printf "\033]PC{{colors.on_tertiary_container.default.hex_stripped}}"
    printf "\033]PD{{colors.on_primary_container.default.hex_stripped}}"
    printf "\033]PE{{colors.on_secondary_container.default.hex_stripped}}"
    printf "\033]PF{{colors.on_surface_variant.default.hex_stripped}}"
    
    clear # Force refresh
fi
