#!/bin/sh

STATUS=$(playerctl status 2>/dev/null)

if [ -z "$STATUS" ] || [ "$STATUS" = "Stopped" ]; then
    echo ""
    exit 0
fi

TITLE=$(playerctl metadata title 2>/dev/null)

if [ ${#TITLE} -gt 30 ]; then
    TITLE=$(echo "$TITLE" | cut -c 1-27)...
fi

if [ "$STATUS" = "Playing" ]; then
    ICON=""
else
    ICON=""
fi

echo "$TITLE   %{A1:playerctl previous:}%{A} %{A1:playerctl play-pause:} $ICON %{A} %{A1:playerctl next:}%{A}"

