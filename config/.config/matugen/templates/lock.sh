#!/bin/sh

blank="00000000"
circle_bg={{colors.on_primary.default.hex}}
circle={{colors.primary.default.hex}}
error={{colors.error.default.hex}}

i3-msg workspace number 42

i3lock -n -c $blank \
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

i3-msg workspace back_and_forth
