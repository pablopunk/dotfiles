#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

preferences_dir="$HOME/Library/Preferences"
file="com.bahoom.HyperSwitch.plist"
mkdir -p "$preferences_dir"
ln -svf "$dir/$file" "$preferences_dir/$file"
