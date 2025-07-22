#!/bin/bash

# Dynamic workspace manager for sketchybar
# This script manages workspace items dynamically

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

# Function to add a workspace item
add_workspace_item() {
    local ws="$1"
    local escaped_ws=$(echo "$ws" | sed 's/[^a-zA-Z0-9]/_/g')
    
    # Check if item already exists
    if ! sketchybar --query space.$escaped_ws >/dev/null 2>&1; then
        echo "Adding workspace: $ws"
            sketchybar --add item space.$escaped_ws left \
        --subscribe space.$escaped_ws aerospace_workspace_change \
        --set space.$escaped_ws \
            background.color=0x00000000 \
            background.corner_radius=6 \
            background.height=24 \
            background.drawing=off \
            label.align=center \
            label.width=24 \
            label="$ws" \
            click_script="aerospace workspace $ws" \
            script="$PLUGIN_DIR/aerospace.sh $ws"
    fi
}

# Function to remove a workspace item
remove_workspace_item() {
    local ws="$1"
    local escaped_ws=$(echo "$ws" | sed 's/[^a-zA-Z0-9]/_/g')
    
    # Check if item exists and remove it
    if sketchybar --query space.$escaped_ws >/dev/null 2>&1; then
        echo "Removing workspace: $ws"
        sketchybar --remove space.$escaped_ws
    fi
}

# Function to update workspace items
update_workspaces() {
    # Get current active workspaces
    local current_active=()
    for ws in $(aerospace list-workspaces --all 2>/dev/null); do
        if aerospace list-windows --workspace "$ws" 2>/dev/null | grep -q .; then
            current_active+=("$ws")
        fi
    done
    
    # Get currently displayed workspaces
    local displayed_workspaces=()
    for item in $(sketchybar --query space | jq -r '.[] | select(.name | startswith("space.")) | .name' 2>/dev/null); do
        local ws_name=$(sketchybar --query "$item" | jq -r '.label.string' 2>/dev/null)
        if [ "$ws_name" != "null" ] && [ -n "$ws_name" ]; then
            displayed_workspaces+=("$ws_name")
        fi
    done
    
    # Add new active workspaces
    for ws in "${current_active[@]}"; do
        add_workspace_item "$ws"
    done
    
    # Remove workspaces that are no longer active
    for ws in "${displayed_workspaces[@]}"; do
        local is_still_active=false
        for active_ws in "${current_active[@]}"; do
            if [ "$ws" = "$active_ws" ]; then
                is_still_active=true
                break
            fi
        done
        
        if [ "$is_still_active" = false ]; then
            remove_workspace_item "$ws"
        fi
    done
}

# Main execution
case "${1:-update}" in
    "update")
        update_workspaces
        ;;
    "add")
        if [ -n "$2" ]; then
            add_workspace_item "$2"
        fi
        ;;
    "remove")
        if [ -n "$2" ]; then
            remove_workspace_item "$2"
        fi
        ;;
    *)
        echo "Usage: $0 [update|add <workspace>|remove <workspace>]"
        exit 1
        ;;
esac 