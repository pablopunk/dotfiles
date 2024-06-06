#!/bin/bash

if [[ $(uname) == "Darwin" ]]; then
  if ! hash sketchybar 2>/dev/null; then
    brew_install FelixKratz/formulae/sketchybar
    brew_install jq
    brew_install homebrew/cask-fonts/font-sf-pro
    brew_install sf-symbols
    curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v1.0.16/sketchybar-app-font.ttf -o $HOME/Library/Fonts/sketchybar-app-font.ttf
  fi
fi

