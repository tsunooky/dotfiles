#!/bin/sh

blank="00000000"
circle_bg=#0c305f
circle=#abc7ff
error=#ffb4ab

i3lock -c $blank \
    --indicator \
    --inside-color=$blank \
    --insidever-color=$blank \
    --insidewrong-color=$blank \
    --ring-color=$circle_bg \
    --ringver-color=$circle \
    --ringwrong-color=$error \
    --keyhl-color=$circle \
    --bshl-color=$error \
    --line-color=$blank \
    --verif-color=$circle \
    --wrong-color=$error \
    --modif-color=$circle_bg \
