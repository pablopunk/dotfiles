#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

target_dir=""
if [[ "$OSTYPE" == "darwin"* ]]; then
  target_dir="$HOME/Library/Application Support/Sublime Text/Packages"
elif [[ "$OSTYPE" == "linux-gnu" ]]; then
  target_dir="$HOME/.config/sublime-text/Packages"
fi

mkdir -p "$target_dir"
rm -rf "$target_dir/User"
ln -svf "$dir/User" "$target_dir/User"
