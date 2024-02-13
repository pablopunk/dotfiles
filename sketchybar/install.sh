#!/bin/bash

dir="$(dirname $(realpath $0))"

# check macos
if [[ $(uname) == "Darwin" ]]; then
  brew tap FelixKratz/formulae > /dev/null 2>&1
  brew install sketchybar > /dev/null 2>&1
  brew install jq > /dev/null 2>&1
  brew tap homebrew/cask-fonts > /dev/null 2>&1
  brew install font-sf-pro > /dev/null 2>&1
  brew install --cask sf-symbols > /dev/null 2>&1
  curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v1.0.16/sketchybar-app-font.ttf -o $HOME/Library/Fonts/sketchybar-app-font.ttf > /dev/null 2>&1
fi

rm -rf ~/.config/sketchybar
ln -sf $dir ~/.config/sketchybar
