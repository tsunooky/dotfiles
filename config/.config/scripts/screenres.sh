#!/bin/sh

OUTPUT=$(xrandr | grep " connected primary" | awk '{print $1}')

if [ -z "$OUTPUT" ]; then
    OUTPUT=$(xrandr | grep " connected" | awk '{print $1}')
fi

RES=$(xrandr | awk '/ [0-9]+x[0-9]+ / {print $1; exit}')

RATE=$(xrandr | grep -A1 "$RES" | tail -n1 | sed 's/[*+]//g' | awk '{for(i=1;i<=NF;i++)print $i}' | sort -nr | head -n1)

if [ -n "$OUTPUT" ] && [ -n "$RES" ] && [ -n "$RATE" ]; then
    xrandr --output "$OUTPUT" --mode "$RES" --rate "$RATE"
fi

