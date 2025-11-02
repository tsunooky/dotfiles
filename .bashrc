# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;34m\]\u@\h\[\033[00m\]:\[\033[01;35m\]\w\[\033[00m\]\$ '


# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

#Copy functions
clip()
{
    cat $@ | xsel -b
}

clipfiles()
{
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

gitall() {
    git add .
    echo "Current status:"
    git status
    echo -n "Enter your commit message (or 'q' to quit): "
    read msg
    if [[ "$msg" == "q" ]]; then
        echo "Operation aborted."
        return 0
    fi
    if [ -z "$msg" ]; then
        echo "Commit message cannot be empty. Aborting."
        return 1
    fi
    git commit -m "$msg"
    if [ $? -ne 0 ]; then
        echo "Commit failed. Aborting push."
        return 1
    fi
    git push
}

# LSD aliases
alias ls='lsd'
alias sl='lsd'
alias la='lsd -A'
alias ll='lsd -l'
alias tree='lsd --tree'

# Custom aliases
alias update='sudo pacman -Syu'
alias ff='fastfetch'
alias bg='~/.config/scripts/change_wallpaper.sh'
alias rbg='(~/.config/scripts/random_wallpaper.sh &)'

# Config aliases
alias conf='cd ~/.config/'
alias confly='sudo nvim /etc/ly/config.ini'
alias conflybg='sudo systemctl edit --full ly.service'
alias confrc='vim ~/.bashrc'
alias confi3='vim ~/.config/i3/config'
alias confmat='vim ~/.config/matugen/config.toml'
alias conftemp='vim ~/.config/matugen/templates/'
alias confbar='vim ~/.config/polybar/config.ini'

# C aliases
alias gccall='gcc -std=c99 -pedantic -Werror -Wall -Wextra -Wvla *.c -o main'
alias gccallsan='gcc -std=c99 -pedantic -Werror -Wall -Wextra -Wvla *.c -o main'


export PATH=$PATH:/home/adrien/.local/bin/
export PATH=$PATH:~/.cargo/bin/
eval "$(starship init bash)"
