#!/bin/sh

send_notif()
{
    local current=$(brightnessctl g)
    local max=$(brightnessctl m)

    local percent=$((current * 100 / max))

    dunstify -h string:x-dunst-stack-tag:brightness "Brightness : $percent%" -t 2000
}

STEP=5

case "$1" in 
    up)
        brightnessctl s +$STEP%
        send_notif
        ;;
    down)
        brightnessctl s $STEP%-
        send_notif
        ;;
    *)
        exit 1;;
esac
