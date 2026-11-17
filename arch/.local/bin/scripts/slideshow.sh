#!/bin/bash

# Set image directory
IMAGES_DIR=~/Pictures/background

# Started from a key binding, so stderr goes nowhere -- say it on screen
if [ ! -d "$IMAGES_DIR" ]; then
    swaynag -t warning -m "slideshow.sh: $IMAGES_DIR doesn't exist; put some images in it"
    exit 1
fi

# Imv
imv -f -t 10 "$IMAGES_DIR"
