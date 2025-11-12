#!/bin/bash

# --- Configuration ---
TERMINAL=${TERMINAL:-alacritty} # Default terminal. Overridden by $TERMINAL.
CONFIG_LIST="$HOME/.config/scripts/config.list" # Path to the config list.
DELIM="::" # Delimiter between display name and file path.

# --- Functions ---

show_menu() {
    mkdir -p "$(dirname "$CONFIG_LIST")"
    touch "$CONFIG_LIST"

    # Extract just the names (before '::') for Rofi.
    options=$(awk -F "$DELIM" '{print $1}' "$CONFIG_LIST" | sort)

    if [[ -z "$options" ]]; then
        rofi -e "No config found. Add one with '$0 -a <Name> <Path>'"
        exit 1
    fi

    choice=$(echo -e "$options" | rofi -dmenu -i -p "🔧 Edit Config:")

    if [[ -n "$choice" ]]; then
        # Find the path corresponding to the chosen name.
        file_to_edit=$(grep "^${choice}${DELIM}" "$CONFIG_LIST" | awk -F "$DELIM" '{print $2}')

        # Expand tilde (~) and $HOME variables.
        file_to_edit=$(echo "$file_to_edit" | sed "s|^~|$HOME|; s|\$HOME|$HOME|g")

        if [[ -n "$file_to_edit" ]]; then
            $TERMINAL -e vim "$file_to_edit"
        else
            rofi -e "Error: Path not found for '$choice'."
        fi
    else
        echo "Operation cancelled."
    fi
}

add_config() {
    local name="$1"
    local path="$2"

    if [[ -z "$name" ]] || [[ -z "$path" ]]; then
        echo "Usage: $0 -a <MenuName> <Path>"
        echo "Example: $0 -a \"Bashrc\" \"~/.bashrc\""
        exit 1
    fi

    # Check for duplicate names.
    if grep -q "^${name}${DELIM}" "$CONFIG_LIST"; then
        rofi -e "Error: The name '$name' already exists."
        exit 1
    fi

    echo "${name}${DELIM}${path}" >> "$CONFIG_LIST"
    rofi -e "Config '$name' added!"
}

# --- Main Logic ---

case "$1" in
    -a)
        add_config "$2" "$3"
        ;;
    --help|-h)
        echo "Usage: $0"
        echo "       $0 -a <Name> <Path>"
        ;;
    *)
        show_menu
        ;;
esac
