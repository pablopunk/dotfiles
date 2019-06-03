#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

vscode_settings_dir="$HOME/Library/Application\ Support/Code/User"
mkdir -p "$vscode_settings_dir"
ln -svf $dir/settings.json "$vscode_settings_dir"/settings.json
