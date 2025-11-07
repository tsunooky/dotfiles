#!/bin/sh

RES="$(xrandr | awk '/ [0-9]+x[0-9]+ / {print $1; exit}')"

if res == "1920x1080"; then
    echo "11"
else
    echo "22"
fi
