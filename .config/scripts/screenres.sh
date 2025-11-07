#!/bin/sh

RES="$(xrandr | awk '/ [0-9]+x[0-9]+ / {print $1; exit}')"

xrandr --output eDP-1 --mode $RES --rate 120
