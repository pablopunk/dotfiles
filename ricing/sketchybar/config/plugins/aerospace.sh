#!/bin/bash

# Aerospace workspace plugin for sketchybar
# Usage: aerospace.sh <workspace_id>

WORKSPACE_ID=$1
CURRENT_WORKSPACE=$(aerospace list-workspaces --focused 2>/dev/null || echo "1")
ESCAPED_WORKSPACE_ID=$(echo "$WORKSPACE_ID" | sed 's/[^a-zA-Z0-9]/_/g')

if [ "$WORKSPACE_ID" = "$CURRENT_WORKSPACE" ]; then
    # Current workspace - always show and highlight
    sketchybar --set space.$ESCAPED_WORKSPACE_ID \
        background.drawing=on \
        background.color=0x80b4befe \
        label.font.style=Bold
else
    # Other active workspaces - show but don't highlight
    sketchybar --set space.$ESCAPED_WORKSPACE_ID \
        background.drawing=on \
        background.color=0xff1e1e2e \
        label.font.style=Regular
fi 