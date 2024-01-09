#!/bin/bash

mkdir -p ~/.config/alacritty
ln -svf "$(dirname $(realpath $0))"/alacritty.yml ~/.config/alacritty/alacritty.yml

[[ -d ~/.config/alacritty/catppuccin ]] || git clone --depth 1 --branch yaml https://github.com/catppuccin/alacritty.git ~/.config/alacritty/catppuccin 2> /dev/null

