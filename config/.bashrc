# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ----------------------------
# ENVIRONMENT VARIABLES & PATH
# ----------------------------

export PATH=$PATH:~/.local/bin/
export PATH=$PATH:~/.cargo/bin/

# TAB colors
if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b)"
fi

# Use bat for colored man pages
export MANPAGER="sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\'' | bat -p -lman'"

# -----------------------
# HISTORY & SHELL OPTIONS
# -----------------------

HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
HISTIGNORE="&:[bf]g:exit:ls:lsd:ll:la:sl:clear:history"
shopt -s histappend
shopt -s checkwinsize

# ------------------------------
# GENERAL ALIASES & REPLACEMENTS
# ------------------------------

# Colorize standard commands
alias diff='diff --color=auto'
alias grep='grep --color=auto'
alias ip='ip -color=auto'
alias cat='bat -pp'
alias cqt='bat -pp'
alias l='lsd'
alias ls='lsd'
alias sl='lsd'
alias la='lsd -A'
alias ll='lsd -l'
alias tree='lsd --tree'

# -----------
# GIT ALIASES
# -----------

alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gpu='git pull'
alias gl='git log --oneline --graph --decorate'
alias gt='git tag -ma'
alias gpt='git push --follow-tags'
alias gd='git diff --name-only --relative --diff-filter=d -z | xargs -0 bat --diff'

# Go to the root of current git repository
cdg() {
    local root_dir
    root_dir=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -n "$root_dir" ]]; then
        cd "$root_dir"
    else
        echo "Error : You are not in a Git repository." >&2
        return 1
    fi
}

# ---------------------
# EPITA & C PROGRAMMING
# ---------------------

# C Dev shortcuts
alias makec="make && make check && make clean"
alias gcw="gcc -std=c99 -pedantic -Werror -Wall -Wextra -Wvla"
alias cf="clang-format -i"

# Quick extraction from Downloads directory
alias tarpls='mv ~/Downloads/*.tar . && tar -xvf *.tar && rm *.tar'
alias zippls='mv ~/Downloads/*.zip . && unzip *.zip && rm *.zip'

# -----------------
# UTILITY FUNCTIONS
# -----------------

# Spawns a new terminal in the current directory
alias double='alacritty --working-directory "$PWD" > /dev/null 2>&1 & disown'

# Create a directory and enter it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Smart archive extractor
extract() {
  if [ -f $1 ] ; then
    case $1 in
          *.tar.bz2)     tar xvjf $1    ;;
          *.tar.gz)      tar xvzf $1    ;;
          *.bz2)         bunzip2 $1     ;;
          *.rar)         unrar x $1     ;;
          *.gz)          gunzip $1      ;;
          *.tar)         tar xvf $1     ;;
          *.tbz2)        tar xvjf $1    ;;
          *.zip)         unzip $1       ;;
          *.Z)           uncompress $1  ;;
          *.7z)          7z x $1        ;;
          *)             echo "Don't know how to extract '$1'..."
      esac
    else
      echo "'$1' is not a valid file!"
    fi
}

# Clipboard utilities
copy() {
    cat "$@" | xsel -b
}

copyfiles() {
    (
        for file in "$@"; do
            if [ -f "$file" ]; then
                echo "$file"
                cat "$file"
                echo
            fi
        done
    ) | xsel -b
}

# ------
# CONFIG
# ------

# Wallpaper & Matugen scripts
alias bg='~/.config/scripts/change_wallpaper.sh'
alias rbg='(~/.config/scripts/random_wallpaper.sh &)'
alias bgdir='cd .wallpapers'
bgadd() {
    cp "$1" ~/.wallpapers
}

# Custom aliases
alias clip='copy'
alias clipfiles='copyfiles'
alias repo='cdg'
alias update='sudo pacman -Syu'
alias ff='fastfetch'
alias clsw="rm -r ~/.cache/vim/swap"

# Config alias
alias conf="~/.config/scripts/edit_config.sh"

# ----- Prompt init with starship -----
eval "$(starship init bash)"

