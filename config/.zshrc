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

export EDITOR=vim

export PGDATA="$HOME/postgres_data"
export PGHOST="/tmp"

export PATH=$PATH:~/.local/bin/
export PATH=$PATH:~/.cargo/bin/

# Ensure unique paths (Zsh specific)
typeset -U path
export PATH

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
HISTSIZE=10000
SAVEHIST=20000

# Share history and ignore duplicates
setopt APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
HISTORY_IGNORE="(lsd|sl|ls|l|ll|la|cd|exit|clear|history|bg|fg)"

# Navigation options
setopt AUTO_CD

# Fix weird keys mapping
bindkey -e
bindkey "^[[H"  beginning-of-line      # Home
bindkey "^[[F"  end-of-line            # End
bindkey "^[[3~" delete-char            # Delete
bindkey "^?"    backward-delete-char   # Backspace
# Fix Ctrl + Arrows
bindkey '^[[1;5C' forward-word         # Ctrl + Right
bindkey '^[[1;5D' backward-word        # Ctrl + Left
# Fix Home/End variants
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line
# Other fixes
autoload -U select-word-style
select-word-style bash
bindkey \^U backward-kill-line

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
alias gl="git log --graph --abbrev-commit --decorate --format=format:'%C(bold green)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold yellow)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all"
alias gt='git tag -ma'
alias gpt='git push --follow-tags'
alias gd='git diff | bat -pp'

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

# All in one git command
gg() {
    cdg
    git add .
    git commit -m "added features"
    if [ $# -eq 1 ]; then
        git tag -ma $1
        git push --follow-tags
    else
        git push
    fi
    cd - > /dev/null
}

# ---------------------
# EPITA & C PROGRAMMING
# ---------------------

# Spawns a new terminal in the current directory
alias double='alacritty --working-directory "$PWD" > /dev/null 2>&1 & disown'

# School shortcuts
alias intra="firefox https://intra.forge.epita.fr/"
alias moodle="firefox https://moodle.epita.fr/my/"
alias forge="firefox https://cri.epita.fr/"

# C Dev shortcuts
alias makec="make && make check && make clean"
alias gcw="gcc -std=c99 -pedantic -Werror -Wall -Wextra -Wvla"
alias cf="clang-format -i"

# SQL alias
alias sqlsetup='~/.config/scripts/setup_sql.sh'
alias sqlserv='postgres -k "$PGHOST"'
alias sqlfix='~/.config/scripts/sqlfluff fix'
sqlrun()
{
    if [ $# -ne 1 ]; then
        echo 'usage: sqlrun <file>.sql'
    elif [ ! -f $1 ]; then
        echo "error : $1: file not found"
    else
        OUTPUT_FILE=/tmp/sqloutput.csv
        echo "(empty)" > $OUTPUT_FILE
        psql roger_roger -f $@ > $OUTPUT_FILE
        bat -p $OUTPUT_FILE
        rm $OUTPUT_FILE
    fi
}

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

clipall() {
    find . -type d -name '.git' -prune -o -type f -print0 | while IFS= read -r -d '' file; do
        if file "$file" | grep -q "text"; then
            echo "[$file] :"
            cat "$file"
            echo ""
        fi
    done | xsel -b
    
    echo "Clipped everything recursively from ./* (excluding .git and binaries) !"
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
alias todo="~/.config/scripts/todo"

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
