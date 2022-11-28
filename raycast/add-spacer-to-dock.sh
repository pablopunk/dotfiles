#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Add Spacer to Dock
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName MacOS Utils

# Documentation:
# @raycast.description Add small spacer to dock and restart it
# @raycast.author pablopunk
# @raycast.authorURL https://pablopunk.com

defaults write com.apple.dock persistent-apps -array-add '{"tile-type"="small-spacer-tile";}'; killall Dock

