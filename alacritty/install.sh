#!/bin/bash

# get script directory
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mkdir -p "$HOME/.config/alacritty"
ln -svf "$dir/alacritty.yml" "$HOME/.config/alacritty/alacritty.yml"
