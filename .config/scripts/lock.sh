#!/bin/sh

CACHE_FILE="$HOME/.cache/wal/colors.json"

if [ ! -f "$CACHE_FILE" ]; then
    notify-send -t 5000 -u critical "ERROR IN LOCK.SH" " $CACHE_FILE does not exist"
    exit 1
fi

COLOR1=$(jq -r '.colors.color4' "$CACHE_FILE")
COLOR2=$(jq -r '.colors.color2' "$CACHE_FILE")
COLOR3=$(jq -r '.colors.color1' "$CACHE_FILE")

i3lock -c 00000000 \
    --indicator \
    --inside-color=00000000 \
    --insidever-color=00000000 \
    --insidewrong-color=00000000 \
    --ring-color=$COLOR1 \
    --ringver-color=$COLOR2 \
    --ringwrong-color=$COLOR3 \
    --keyhl-color=$COLOR2 \
    --bshl-color=$COLOR3 \
    --line-color=00000000 \
    --verif-color=$COLOR2 \
    --wrong-color=$COLOR3 \
    --modif-color=$COLOR1 \
