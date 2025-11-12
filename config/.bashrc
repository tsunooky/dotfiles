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

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

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
alias clsw="rm -r ~/.cache/vim/swap"
alias makec="make && make check && make clean"
alias tarpls='mv ~/Downloads/*.tar . && tar -xvf *.tar && rm *.tar'

# Epita alias
alias intra="firefox https://intra.forge.epita.fr/"
alias moodle="firefox https://moodle.epita.fr/my/"
alias forge="firefox https://cri.epita.fr/"

# conf alias
alias conf="~/.config/scripts/edit_config.sh"

# C aliases
alias gccall='gcc -std=c99 -pedantic -Werror -Wall -Wextra -Wvla *.c -o main'
alias gccallsan='gcc -std=c99 -pedantic -Werror -Wall -Wextra -Wvla *.c -o main'


export PATH=$PATH:/home/adrien/.local/bin/
export PATH=$PATH:~/.cargo/bin/
eval "$(starship init bash)"
