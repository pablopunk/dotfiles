#!/bin/bash

if [[ $(uname) == "Darwin" ]]; then
  brew_list="$(cat /tmp/brew_list.txt)" # cached list
  [[ -z $brew_list ]] && brew_list="$(brew list)"

  if [[ -z "$(echo $brew_list | grep -w sketchybar)" ]]; then
    brew tap FelixKratz/formulae
    brew tap homebrew/cask-fonts
    brew install sketchybar jq font-sf-pro sf-symbols
    curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v1.0.16/sketchybar-app-font.ttf -o $HOME/Library/Fonts/sketchybar-app-font.ttf
  fi
fi

