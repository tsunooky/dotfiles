#!/bin/sh


set4k()
{

    echo "Xft.dpi: 192
Xft.autohint: 0
Xft.lcdfilter: lcddefault
Xft.hintstyle: hintfull
Xft.hinting: 1
Xft.antialias: 1
Xft.rgba: rgb" > ~/.Xresources

}

setDPI()
{
    sed -i "s/{{DPI}}/$1/g" ~/.config/polybar/config.ini
    echo "Xft.dpi: $1" > ~/.Xresources
}

exec < /dev/tty

read -p "Are you using a 4K monitor? [Y/n] " response_4k

response_4k_lower=${response_4k,,}

if [[ "$response_4k_lower" != "n" ]]; then
    set4k
else
    read -p "What DPI do you want to use? (e.g., 96, 120, 144) " response_dpi

    if [[ -n "$response_dpi" ]]; then
        setDPI "$response_dpi" 
    else
        setDPI "96"
    fi
fi
