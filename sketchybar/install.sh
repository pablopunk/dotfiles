#!/bin/bash

dir="$(dirname $(realpath $0))"

# check macos
if [[ $(uname) == "Darwin" ]]; then
  if [[ -z "$(brew list | grep -w sketchybar)" ]]; then
    echo
    echo -e "\033[31m⨯ sketchybar is not installed\033[0m"
    echo
    echo brew tap FelixKratz/formulae
    echo brew install sketchybar jq
    echo brew tap homebrew/cask-fonts
    echo brew install font-sf-pro
    echo brew install --cask sf-symbols
    echo curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v1.0.16/sketchybar-app-font.ttf -o $HOME/Library/Fonts/sketchybar-app-font.ttf
    echo
  fi
fi

rm -rf ~/.config/sketchybar
ln -sf $dir ~/.config/sketchybar
