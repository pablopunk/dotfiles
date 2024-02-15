#!/bin/bash

if [[ $(uname) == "Darwin" ]] && [[ -z $(brew list | grep sketchybar) ]]; then
  brew tap FelixKratz/formulae
  brew tap homebrew/cask-fonts
  brew install sketchybar jq font-sf-pro sf-symbols
  curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v1.0.16/sketchybar-app-font.ttf -o $HOME/Library/Fonts/sketchybar-app-font.ttf
fi

