#!/bin/bash

mkdir -p ~/.config/alacritty
ln -svf "$(dirname $(realpath $0))"/alacritty.toml ~/.config/alacritty/alacritty.toml

[[ -d ~/.config/alacritty/catppuccin ]] || git clone https://github.com/catppuccin/alacritty.git ~/.config/alacritty/catppuccin 2> /dev/null

