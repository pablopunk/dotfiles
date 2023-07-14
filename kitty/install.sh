#!/bin/bash

function preinstall {
  rm -rf ~/.config/kitty
  mkdir -p ~/.config/kitty
  git clone --depth 1 https://github.com/catppuccin/kitty ~/.config/kitty/themes
}

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

preinstall && \
  ln -svf $dir/kitty.conf ~/.config/kitty/kitty.conf
  cp ~/.config/kitty/themes/themes/* ~/.config/kitty/themes/
