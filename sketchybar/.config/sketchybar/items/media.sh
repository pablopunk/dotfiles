#!/bin/bash

sketchybar --add item media l \
           --set media label.color=$ACCENT_COLOR \
                       label.max_chars=32 \
                       icon.padding_left=0 \
                       scroll_texts=on \
                       icon=􁏵             \
                       icon.color=$ACCENT_COLOR   \
                     background.drawing=off \
                       script="$PLUGIN_DIR/media.sh" \
           --subscribe media media_change
