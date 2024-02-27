#!/bin/sh

source "$HOME/.config/sketchybar/colors.sh"

RAM=$(memory_pressure | grep -oE 'System-wide memory free percentage: ([0-9]+)%' | awk '{print 100 - $NF}')

sketchybar --set $NAME label="$RAM%"
