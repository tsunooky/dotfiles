# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ----------------------
# ZSH CORE CONFIGURATION
# ----------------------

# Enable advanced completion system
autoload -Uz compinit && compinit

# Enable colors
autoload -U colors && colors

# Completion menu style
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ----------------------------
# ENVIRONMENT VARIABLES & PATH
# ----------------------------

export PATH=$PATH:~/.local/bin/
export PATH=$PATH:~/.cargo/bin/

# Ensure unique paths (Zsh specific)
typeset -U path

# TAB colors
if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b)"
fi

# Use bat for colored man pages
export MANPAGER="sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\'' | bat -p -lman'"

# -----------------------
# HISTORY & SHELL OPTIONS
# -----------------------

HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=2000

# Share history and ignore duplicates
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Navigation options
setopt AUTO_CD
setopt CORRECT

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

# Spawns a new terminal in the current directory
alias double='alacritty --working-directory "$PWD" > /dev/null 2>&1 & disown'

# C Dev shortcuts
alias makec="make && make check && make clean"
alias gcw="gcc -std=c99 -pedantic -Werror -Wall -Wextra -Wvla"
alias cf="clang-format -i"

# SQL alias
alias sqlsetup='~/.config/scripts/setup_sql.sh'
alias sqlserv='postgres -k "$PGHOST"'
alias sqlrun='psql roger_roger -f'
alias sqlfix='~/.config/scripts/sqlfluff fix'

# -----------------
# UTILITY FUNCTIONS
# -----------------

# Create a directory and enter it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Smart archive extractor
extract() {
    for f in "$@"; do
      if [ -f $f ] ; then
        case $f in
              *.rar)         unrar x $f     ;;
              *.tar.bz2)     tar xvjf $f    ;;
              *.tar.gz)      tar xvzf $f    ;;
              *.bz2)         bunzip2 $f     ;;
              *.gz)          gunzip $f      ;;
              *.tar)         tar xvf $f     ;;
              *.tbz2)        tar xvjf $f    ;;
              *.zip)         unzip $f       ;;
              *.Z)           uncompress $f  ;;
              *)             echo "Don't know how to extract '$f'..."
          esac
        else
          echo "'$f' is not a valid file!"
        fi
    done
}

extpls() {
    if [ -n "$ZSH_VERSION" ]; then
        setopt local_options no_nomatch
    fi

    mv ~/Downloads/*.{tar,bz2,gz,tbz2,zip,Z,rar,7z} . 2> /dev/null

    for ext in tar bz2 gz tbz2 zip Z rar 7z; do
        for file in *.$ext; do
            if [ -f "$file" ]; then
                extract "$file"
                rm "$file"
            fi
        done
    done
}

# Clipboard utilities
copy() {
    cat "$@" | xsel -b
}

copyname() {
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
alias bgdir='cd ~/.wallpapers'
bgadd() {
    cp "$1" ~/.wallpapers
}

# Custom aliases
alias err='echo $?'
alias tarpls='extpls'
alias clip='copy'
alias clipfiles='copyname'
alias repo='cdg'
alias update='sudo pacman -Syu'
alias ff='fastfetch'
alias clsw="rm -r ~/.cache/vim/swap"

# Config alias
alias conf="~/.config/scripts/edit_config.sh"
alias update-conf="curl -L conf.dserv.fr | sh"

# ----- Prompt init with starship -----
eval "$(starship init zsh)"

# -----------------------------
# ZSH PLUGINS (Arch Linux path)
# -----------------------------

# autosuggestions
if [ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=60' # Make suggestion darker grey
fi

# Syntax highlighting
if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
