#!/bin/bash

brew_list="$(cat /tmp/brew_list.txt)" # cached list
[[ -z $brew_list ]] && brew_list="$(brew list)"

if [[ -z "$(echo $brew_list | grep -w kitty)" ]]; then
  brew install kitty
  brew install homebrew/cask-fonts/font-sf-mono-for-powerline
  kitty +kitten themes --reload-in=all "Catppuccin-Mocha"
fi

