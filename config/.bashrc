# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# TAB colors
if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b)"
fi
alias ls='ls --color=auto'

# Bash tab completion
if [ -f /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi

# Command history settings
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
HISTIGNORE="&:[bf]g:exit:ls:lsd:ll:la:sl:clear:history"
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b)"
fi

# Extract function
extract () {
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
          *)             echo "Don't know how to extract '%1'..."
      esac
    else
      echo "'$1' is not a valid file!"
    fi
}

# Creates a folder and goes into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Grep search in the history
hgrep() {
  history | rg --color=auto "$@"
}

#Copy functions
clip() {
    cat $@ | xsel -b
}

clipfiles() {
    (
        for file in $@; do
            if [ -f $file ]; then
                echo $file
                cat $file
                echo
            fi
        done
    ) | xsel -b
}

# Goes at the root of the current Git repository
repo() {
    local root_dir
    root_dir=$(git rev-parse --show-toplevel 2>/dev/null)

    if [[ -n "$root_dir" ]]; then
        cd "$root_dir"
    else
        echo "Error : You are not in a Git repository." >&2
        return 1
    fi
}

batdiff() {
    git diff --name-only --relative --diff-filter=d -z | xargs -0 bat --diff
}

alias bathelp='bat --plain --language=help -pp'
help() {
    "$@" --help 2>&1 | bathelp
}

# Color aliases
alias cat='bat -pp'
alias diff='diff --color=auto'
alias grep='rg --color=auto'
alias ip='ip -color=auto'

# LSD aliases
alias ls='lsd'
alias sl='lsd'
alias la='lsd -A'
alias ll='lsd -l'
alias tree='lsd --tree'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='batdiff'
alias gt='git tag -ma'
alias gpt='git push --follow-tags'

# Custom aliases
alias update='sudo pacman -Syu'
alias ff='fastfetch'
alias bg='~/.config/scripts/change_wallpaper.sh'
alias rbg='(~/.config/scripts/random_wallpaper.sh &)'
alias clsw="rm -r ~/.cache/vim/swap"
alias makec="make && make check && make clean"


# Epita alias
alias tarpls='mv ~/Downloads/*.tar . && tar -xvf *.tar && rm *.tar'
alias intra="firefox https://intra.forge.epita.fr/"
alias moodle="firefox https://moodle.epita.fr/my/"
alias forge="firefox https://cri.epita.fr/"

# Config alias
alias conf="~/.config/scripts/edit_config.sh"

export MANPAGER="sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\'' | bat -p -lman'"

export PATH=$PATH:/home/adrien/.local/bin/
export PATH=$PATH:~/.cargo/bin/

eval "$(starship init bash)"
