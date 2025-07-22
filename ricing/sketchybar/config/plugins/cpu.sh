#!/bin/bash

# CPU usage plugin for sketchybar

CPU_USAGE=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')

if [ -z "$CPU_USAGE" ]; then
	CPU_USAGE="0"
fi

# Color coding based on usage using Catppuccin colors
COLOR=$(echo "$CPU_USAGE" | awk '{
	if ($1 > 80) print "0xfff38ba8"  # Red
	else if ($1 > 60) print "0xfff9e2af"  # Yellow
	else print "0xffa6e3a1"  # Green
}')

sketchybar --set cpu.number label="$CPU_USAGE%" label.color="$COLOR" 