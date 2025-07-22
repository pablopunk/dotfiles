#!/bin/bash

# Aerospace workspace plugin for sketchybar
# Usage: aerospace.sh <workspace_id>

WORKSPACE_ID=$1
CURRENT_WORKSPACE=$(aerospace list-workspaces --focused 2>/dev/null || echo "1")
ESCAPED_WORKSPACE_ID=$(echo "$WORKSPACE_ID" | sed 's/[^a-zA-Z0-9]/_/g')

if [ "$WORKSPACE_ID" = "$CURRENT_WORKSPACE" ]; then
	sketchybar --set space.$ESCAPED_WORKSPACE_ID background.drawing=on label.color=0xff000000
else
	sketchybar --set space.$ESCAPED_WORKSPACE_ID background.drawing=off label.color=0xffffffff
fi 