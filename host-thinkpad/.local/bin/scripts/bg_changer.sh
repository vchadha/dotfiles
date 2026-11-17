#!/bin/bash

if [ ! -d ~/Pictures/background ]; then
    echo "bg_changer.sh: ~/Pictures/background doesn't exist; put some wallpapers in it" >&2
    exit 1
fi

# Get random wallpaper
BACKGROUND_URI=$(ls ~/Pictures/background/ | shuf -n 1)
BACKGROUND_URL="~/Pictures/background/"$BACKGROUND_URI

# Sway msg to set wallpaper
swaymsg -s $SWAYSOCK output eDP-1 bg $BACKGROUND_URL fill

