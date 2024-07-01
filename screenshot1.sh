#!/bin/bash
# Take a screenshot of the screen on the first monitor. Parameter can add a delay.

if [ $# -eq 1 ]; then
    echo "Sleeping for $1 second(s)..."
    sleep "$1"
    grim -g "0,0 1920x1080" ~/Documents/$(date -d "today" +"%Y%m%d%H%M_%s").png
else
    grim -g "0,0 1920x1080" ~/Documents/$(date -d "today" +"%Y%m%d%H%M_%s").png
fi
