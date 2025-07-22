#!/bin/bash

# RAM usage plugin for sketchybar

# Get memory usage using vm_stat
MEMORY_USAGE=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
TOTAL_MEMORY=$(sysctl -n hw.memsize)
MEMORY_USAGE_BYTES=$((MEMORY_USAGE * 4096))
MEMORY_PERCENT=$((MEMORY_USAGE_BYTES * 100 / TOTAL_MEMORY))

if [ -z "$MEMORY_PERCENT" ]; then
	MEMORY_PERCENT="0"
fi

# Color coding based on usage using Catppuccin colors
COLOR=$(echo "$MEMORY_PERCENT" | awk '{
	if ($1 > 80) print "0xfff38ba8"  # Red
	else if ($1 > 60) print "0xfff9e2af"  # Yellow
	else print "0xffa6e3a1"  # Green
}')

sketchybar --set ram.number label="$MEMORY_PERCENT%" label.color="$COLOR" 