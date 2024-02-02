#!/bin/bash

rm -f ~/Library/Preferences/com.surteesstudios.Bartender.plist
mkdir -p ~/Library/Preferences
ln -sf "$(dirname $(realpath $0))"/com.surteesstudios.Bartender.plist ~/Library/Preferences/com.surteesstudios.Bartender.plist


