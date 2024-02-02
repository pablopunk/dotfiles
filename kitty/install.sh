#!/bin/bash

mkdir -p ~/.config/kitty
ln -sf "$(dirname $(realpath $0))"/kitty.conf ~/.config/kitty/kitty.conf

themes_dir=~/.config/kitty/themes
tmp_themes_dir=/tmp/kitty-catppuccin

[ -f $themes_dir/mocha.conf ] && exit

mkdir -p $themes_dir
git clone --depth 1 https://github.com/catppuccin/kitty $tmp_themes_dir
cp $tmp_themes_dir/themes/* $themes_dir
